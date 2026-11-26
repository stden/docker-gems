#!/bin/bash
set -euo pipefail
exec bash "$(dirname "$0")/../ci/publish-image.sh" latex
