#!/bin/sh
# Print one colored heading with an emoji in the GitHub Actions log.
# Usage: ci/heading.sh info|build|test|publish|pass|fail "<text>"
# GitHub shows the first line of each step script as the heading of the step.
# This script keeps the escape codes out of that line.
set -eu

if [ $# -ne 2 ]; then
  echo "Usage: $0 info|build|test|publish|pass|fail <text>" >&2
  exit 2
fi

case $1 in
  info) color='1;96' emoji='🐳' ;;
  build) color='1;96' emoji='🔨' ;;
  test) color='1;93' emoji='🧪' ;;
  publish) color='1;95' emoji='🚀' ;;
  pass) color='1;92' emoji='✅' ;;
  fail) color='1;91' emoji='❌' ;;
  *)
    echo "Unknown heading type: $1. Use info, build, test, publish, pass, or fail." >&2
    exit 2
    ;;
esac

rule='━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
printf '\033[%sm%s\n%s %s\n%s\033[0m\n' "$color" "$rule" "$emoji" "$2" "$rule"
