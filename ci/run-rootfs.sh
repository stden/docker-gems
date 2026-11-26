#!/bin/sh
# Run a command in an extracted image with its environment and working directory.
# Usage: run-rootfs.sh ROOTFS META [--bind HOST:GUEST]... [--workdir DIR] [--user UID:GID] -- CMD...
# PROOT is the static proot binary. PROOT_TMP_DIR must be writable.
set -eu

if [ $# -lt 4 ]; then
  echo "usage: run-rootfs.sh ROOTFS META [--bind HOST:GUEST]... [--workdir DIR] [--user UID:GID] -- CMD..." >&2
  exit 2
fi

ROOT=$1
META=$2
shift 2
PROOT=${PROOT:-proot}
PROOT_TMP_DIR=${PROOT_TMP_DIR:-/tmp/proot}
mkdir -p "$PROOT_TMP_DIR"
export PROOT_TMP_DIR

workdir=$(cat "$META/workdir")
user=0:0
[ -n "$workdir" ] || workdir=/
bind1=
bind2=

while [ $# -gt 0 ]; do
  case $1 in
    --bind)
      if [ -z "$bind1" ]; then
        bind1=$2
      elif [ -z "$bind2" ]; then
        bind2=$2
      else
        echo "only two --bind arguments are supported" >&2
        exit 2
      fi
      shift 2
      ;;
    --workdir)
      workdir=$2
      shift 2
      ;;
    --user)
      user=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "unexpected argument: $1" >&2
      exit 2
      ;;
  esac
done

if [ $# -eq 0 ]; then
  echo "missing command" >&2
  exit 2
fi

# Kaniko records WORKDIR in the image config and does not always add that
# directory to a layer. Docker creates it at start. Create it here too.
case $workdir in
  /*) mkdir -p "$ROOT$workdir" ;;
  *)
    echo "working directory must be absolute: $workdir" >&2
    exit 1
    ;;
esac

# jq expands this variable inside its own expression.
# shellcheck disable=SC2016
q=$(${JQ:-jq} -nr --arg w "$workdir" '$w | @sh')
{
  echo '#!/bin/sh'
  echo 'set -eu'
  cat "$META/exports.sh"
  printf 'cd %s\n' "$q"
  echo 'exec "$@"'
} > "$META/enter.sh"

args=$META/proot.argv
: > "$args"
add() {
  printf '%s\0' "$1" >> "$args"
}

add "$PROOT"
# After a failed browser check, detached processes can stay alive.
add --kill-on-exit
add -i
add "$user"
add -r
add "$ROOT"
add -w
add "$workdir"
add -b
add /proc
add -b
add /dev
if [ -d /dev/shm ]; then
  add -b
  add /dev/shm
fi
if [ -e /etc/resolv.conf ]; then
  add -b
  add /etc/resolv.conf
fi
add -b
add "$META/enter.sh:/enter.sh"
if [ -n "$bind1" ]; then
  add -b
  add "$bind1"
fi
if [ -n "$bind2" ]; then
  add -b
  add "$bind2"
fi
add /bin/sh
add /enter.sh
for arg in "$@"; do
  add "$arg"
done

xargs -0 sh -c 'exec "$@"' sh < "$args"
