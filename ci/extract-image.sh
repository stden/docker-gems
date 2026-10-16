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

  while IFS= read -r entry; do
    entry=${entry#./}
    entry=${entry%/}
    base=${entry##*/}
    [ "$base" = ".wh..wh..opq" ] || continue
    dir=${entry%/*}
    [ "$dir" = "$entry" ] && continue
    if [ -d "$root/$dir" ]; then
      find "$root/$dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    fi
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
    base=${entry##*/}
    case $base in
      .wh..wh..opq)
        rm -f "$root/$entry"
        ;;
      .wh.*)
        name=${base#.wh.}
        case $name in
          ""|.|..) continue ;;
        esac
        dir=${entry%/*}
        if [ "$dir" = "$entry" ]; then
          target=$root/$name
          marker=$root/$base
        else
          target=$root/$dir/$name
          marker=$root/$dir/$base
        fi
        rm -rf "$target"
        rm -f "$marker"
        ;;
    esac
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
