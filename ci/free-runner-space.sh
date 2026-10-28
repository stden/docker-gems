#!/bin/bash
# Remove unused tool directories from the temporary GitHub runner.
# Delete the directories at the same time.
# When one delete fails, report the error after the other deletes.
# Usage: ci/free-runner-space.sh [directory ...]
# With no directory, remove the Android, .NET, and GHC trees.
set -euo pipefail

if (($# == 0)); then
  set -- /usr/local/lib/android /usr/share/dotnet /opt/ghc
fi

pids=()
for path in "$@"; do
  sudo rm -rf -- "$path" &
  pids+=("$!")
done

status=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    status=1
  fi
done

df -h /
exit "$status"
