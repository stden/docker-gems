#!/bin/bash
# Check the Docker Hub overview tests and the saved metadata.
# Usage: ci/check-hub-metadata.sh
set -euo pipefail

python3 -m unittest discover -s ci -p test_hub_metadata.py
python3 ci/hub_metadata.py --check
