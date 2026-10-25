#!/bin/sh
# Unpack a Kaniko --tarPath archive into a root directory.
# Usage: extract-image.sh ARCHIVE ROOTFS META
# META receives the image config: exports.sh, workdir, user, config.json.
set -eu

if [ $# -ne 3 ]; then
  echo "usage: extract-image.sh ARCHIVE ROOTFS META" >&2
  exit 2
fi

ARCHIVE=$1
ROOT=$2
META=$3
JQ=${JQ:-jq}

# Keep layer changes inside the root directory.
check_layer_path() {
  case $2 in
    /*|..|../*|*/../*|*/..)
      echo "Unsafe layer path: $2" >&2
      return 1
      ;;
  esac
  check_parent=${2%/*}
  [ "$check_parent" != "$2" ] || return 0
  while [ "$check_parent" != . ]; do
    if [ -L "$1/$check_parent" ]; then
      echo "Layer path has a symbolic-link parent: $2" >&2
      return 1
    fi
    case $check_parent in
      */*) check_parent=${check_parent%/*} ;;
      *) break ;;
    esac
  done
}

# member is one path inside the archive. The function writes the layer once, beside the
# archive, and removes it before it applies the next layer.
apply_layer() {
  archive=$1
  member=$2
  root=$3
  list=$4
  blob=$list.blob
  tar -xOf "$archive" "$member" > "$blob"
  case $member in
    *.gz|*.tgz)
      tar -tzf "$blob" > "$list"
      ;;
    *)
      tar -tf "$blob" > "$list"
      ;;
  esac

  # Replace non-directory parents first, even when the archive lists children first.
  directories=$list.directories
  sed -n 's|^\(\./\)*||;s|/$||p' "$list" > "$directories"
  LC_ALL=C sort -u "$directories" -o "$directories"
  while IFS= read -r entry; do
    case $entry in ""|.|*/.wh.*|.wh.*) continue ;; esac
    check_layer_path "$root" "$entry"
    target=$root/$entry
    if [ -L "$target" ] || [ ! -d "$target" ]; then
      rm -rf "$target"
    fi
  done < "$directories"
  rm -f "$directories"

  # Whiteouts affect only the parent layers, before this layer creates new files.
  while IFS= read -r entry; do
    entry=${entry#./}
    entry=${entry%/}
    base=${entry##*/}
    case $base in .wh.*) check_layer_path "$root" "$entry" ;; esac
    case $base in
      .wh..wh..opq)
        dir=${entry%/*}
        [ "$dir" != "$entry" ] || dir=.
        if [ -d "$root/$dir" ]; then
          find "$root/$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
        fi
        ;;
      .wh.*)
        name=${base#.wh.}
        case $name in
          ""|.|..) continue ;;
        esac
        dir=${entry%/*}
        if [ "$dir" = "$entry" ]; then
          target=$root/$name
        else
          target=$root/$dir/$name
        fi
        rm -rf "$target"
        ;;
    esac
  done < "$list"

  # Unlink non-directory entries before the tar command.
  while IFS= read -r entry; do
    case $entry in */) continue ;; esac
    entry=${entry#./}
    entry=${entry%/}
    case ${entry##*/} in .|.wh.*) continue ;; esac
    check_layer_path "$root" "$entry"
    target=$root/$entry
    rm -rf "$target"
  done < "$list"

  case $member in
    *.gz|*.tgz)
      tar -xzf "$blob" -C "$root"
      ;;
    *)
      tar -xf "$blob" -C "$root"
      ;;
  esac
  rm -f "$blob"

  while IFS= read -r entry; do
    entry=${entry#./}
    entry=${entry%/}
    case ${entry##*/} in .wh.*) rm -f "$root/$entry" ;; esac
  done < "$list"
}

rm -rf "$ROOT" "$META"
mkdir -p "$ROOT" "$META"

tar -xf "$ARCHIVE" -C "$META" manifest.json
config_rel=$("$JQ" -r '.[0].Config' "$META/manifest.json")
tar -xf "$ARCHIVE" -C "$META" "$config_rel"
cp "$META/$config_rel" "$META/config.json"

"$JQ" -r '.config.Env // [] | .[] | "export " + @sh' "$META/config.json" > "$META/exports.sh"
"$JQ" -r '.config.WorkingDir // "/"' "$META/config.json" > "$META/workdir"
"$JQ" -r '.config.User // ""' "$META/config.json" > "$META/user"

"$JQ" -r '.[0].Layers[]' "$META/manifest.json" > "$META/layers"
while IFS= read -r layer; do
  apply_layer "$ARCHIVE" "$layer" "$ROOT" "$META/layer.list"
done < "$META/layers"

rm -f "$META/layer.list" "$META/layers" "$META/manifest.json" "$META/$config_rel"
