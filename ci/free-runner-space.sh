#!/bin/bash
# Remove unused tool directories from the temporary GitHub runner.
# Usage: ci/free-runner-space.sh
set -euo pipefail

sudo rm -rf /usr/local/lib/android /usr/share/dotnet /opt/ghc
df -h /
