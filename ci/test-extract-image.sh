#!/bin/sh
# Check layer changes with the same tar command as the image runner.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
failures=0

run_case() {
  scenario=$1
  compression=$2
  case_dir=$WORK/$scenario-$compression
  lower=$case_dir/lower
  upper=$case_dir/upper
  result=$case_dir/root
  mkdir -p "$lower" "$upper" "$case_dir/outside"
  printf old > "$lower/keep.txt"
  printf safe > "$case_dir/outside/sentinel"

  case $scenario in
    whiteout_recreate)
      printf old > "$lower/app.txt"
      : > "$upper/.wh.app.txt"
      printf new > "$upper/app.txt"
      ;;
    whiteout_nested)
      mkdir "$lower/app" "$upper/app"
      printf old > "$lower/app/old.txt"
      printf keep > "$lower/app/keep.txt"
      : > "$upper/app/.wh.old.txt"
      ;;
    opaque_root)
      : > "$upper/.wh..wh..opq"
      printf new > "$upper/new.txt"
      ;;
    opaque_nested)
      mkdir "$lower/app" "$upper/app"
      printf old > "$lower/app/old.txt"
      : > "$upper/app/.wh..wh..opq"
      printf new > "$upper/app/new.txt"
      ;;
    directory_file)
      mkdir "$lower/app"
      printf old > "$lower/app/old.txt"
      printf new > "$upper/app"
      ;;
    file_directory)
      printf old > "$lower/app"
      mkdir "$upper/app"
      printf new > "$upper/app/new.txt"
      ;;
    directory_merge)
      mkdir "$lower/app" "$upper/app"
      printf keep > "$lower/app/keep.txt"
      printf new > "$upper/app/new.txt"
      ;;
    symlink_directory|symlink_directory_late|symlink_whiteout_late|symlink_opaque_late|unsafe_parent)
      ln -s "$case_dir/outside" "$lower/app"
      mkdir "$upper/app"
      printf new > "$upper/app/sentinel"
      case $scenario in
        symlink_whiteout_late) : > "$upper/app/.wh.sentinel" ;;
        symlink_opaque_late) : > "$upper/app/.wh..wh..opq" ;;
      esac
      ;;
    symlink_nested_late)
      ln -s "$case_dir/outside" "$lower/app"
      mkdir -p "$upper/app/nested"
      printf new > "$upper/app/nested/sentinel"
      ;;
  esac

  suffix=tar
  tar_flags=-cf
  if [ "$compression" = gzip ]; then
    suffix=tar.gz
    tar_flags=-czf
  fi
  tar "$tar_flags" "$case_dir/lower.$suffix" -C "$lower" .
  case $scenario in
    unsafe_parent) set -- app/sentinel ;;
    symlink_directory_late) set -- --no-recursion app/sentinel app/ ;;
    symlink_whiteout_late) set -- --no-recursion app/sentinel app/.wh.sentinel app/ ;;
    symlink_opaque_late) set -- --no-recursion app/sentinel app/.wh..wh..opq app/ ;;
    symlink_nested_late) set -- --no-recursion app/nested/sentinel app/nested/ app/ ;;
    *) set -- . ;;
  esac
  tar "$tar_flags" "$case_dir/upper.$suffix" -C "$upper" "$@"
  printf '{"config":{}}\n' > "$case_dir/image.json"
  printf '[{"Config":"image.json","Layers":["lower.%s","upper.%s"]}]\n' \
    "$suffix" "$suffix" > "$case_dir/manifest.json"
  tar -cf "$case_dir/image.tar" -C "$case_dir" \
    manifest.json image.json "lower.$suffix" "upper.$suffix"
  status=0
  sh "$ROOT/ci/extract-image.sh" "$case_dir/image.tar" "$result" "$case_dir/meta" \
    > "$case_dir/output" 2>&1 || status=$?

  if [ "$scenario" = unsafe_parent ]; then
    [ "$status" -ne 0 ] && [ "$(cat "$case_dir/outside/sentinel")" = safe ]
    return
  fi
  if [ "$status" -ne 0 ]; then
    cat "$case_dir/output"
    return 1
  fi
  [ -z "$(find "$result" -name '.wh.*' -print)" ] || return 1
  [ "$(cat "$case_dir/outside/sentinel")" = safe ] || return 1
  if [ "$scenario" != opaque_root ]; then
    [ "$(cat "$result/keep.txt")" = old ] || return 1
  fi
  case $scenario in
    whiteout_recreate) [ "$(cat "$result/app.txt")" = new ] ;;
    whiteout_nested)
      [ ! -e "$result/app/old.txt" ] && [ "$(cat "$result/app/keep.txt")" = keep ]
      ;;
    opaque_root) [ ! -e "$result/keep.txt" ] && [ "$(cat "$result/new.txt")" = new ] ;;
    opaque_nested) [ ! -e "$result/app/old.txt" ] && [ "$(cat "$result/app/new.txt")" = new ] ;;
    directory_file) [ -f "$result/app" ] && [ "$(cat "$result/app")" = new ] ;;
    file_directory) [ -d "$result/app" ] && [ "$(cat "$result/app/new.txt")" = new ] ;;
    directory_merge)
      [ "$(cat "$result/app/keep.txt")" = keep ] && [ "$(cat "$result/app/new.txt")" = new ]
      ;;
    symlink_directory|symlink_directory_late|symlink_whiteout_late|symlink_opaque_late)
      [ ! -L "$result/app" ] && [ "$(cat "$result/app/sentinel")" = new ]
      ;;
    symlink_nested_late)
      [ ! -L "$result/app" ] && [ "$(cat "$result/app/nested/sentinel")" = new ]
      ;;
  esac
}

for compression in plain gzip; do
  for scenario in whiteout_recreate whiteout_nested opaque_root opaque_nested \
    directory_file file_directory directory_merge symlink_directory symlink_directory_late \
    symlink_whiteout_late symlink_opaque_late symlink_nested_late unsafe_parent; do
    if run_case "$scenario" "$compression"; then
      echo "PASS $scenario $compression"
    else
      echo "FAIL $scenario $compression"
      failures=$((failures + 1))
    fi
  done
done
[ "$failures" -eq 0 ]
echo 'All image layer checks passed.'
