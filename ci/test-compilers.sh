#!/usr/bin/env bash
# Check the example runner without a compiler installation.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/tmp" "$WORK/current"

cat > "$WORK/bin/compiler" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
tool=${0##*/}
case "$tool" in
  gcc)
    [[ "$SCENARIO" != compile_failure ]] || exit 23
    output=hello_c
    ;;
  g++) output=hello_cpp ;;
  mcs) output=hello_csharp.exe ;;
  dmd) output=hello_d ;;
  ghc) output=hello_haskell ;;
  fpc) output=hello_pascal ;;
  mono) exec bash "$1" ;;
  python3)
    [[ "$SCENARIO" != python_failure ]] || exit 25
    printf 'Hello, world!\n'
    exit
    ;;
  pdflatex|lualatex)
    [[ "$SCENARIO" != pdf_failure ]] || exit 26
    if [[ "$tool" == lualatex ]]; then
      [[ -d "${TEXMFCACHE:-}" && "$TEXMFCACHE" == "$PWD/"* ]]
      [[ "${TEXMFVAR:-}" == "$TEXMFCACHE" ]]
      printf 'Font cache\n' > "$TEXMFCACHE/fonts.cache"
    fi
    for argument in "$@"; do
      if [[ "$argument" == -jobname=* ]]; then
        printf 'PDF\n' > "${argument#-jobname=}.pdf"
      fi
    done
    exit
    ;;
  pdftotext)
    [[ -s "$2" ]]
    if [[ "$SCENARIO" == pdf_wrong_output ]]; then
      printf 'Wrong text\n'
    else
      printf 'Hello, world!\n'
    fi
    exit
    ;;
  *) exit 90 ;;
esac
for argument in "$@"; do
  case "$argument" in
    *.c|*.cpp|*.cs|*.d|*.hs|*.pas) [[ -f "$argument" ]] ;;
  esac
done
cat > "$output" <<'PROGRAM'
#!/usr/bin/env bash
if [[ "${0##*/}" == hello_c ]]; then
  if [[ "$SCENARIO" == runtime_failure ]]; then
    printf 'Runtime diagnostic.\n'
    exit 24
  fi
  if [[ "$SCENARIO" == wrong_output ]]; then
    printf 'Wrong text\n'
    exit
  fi
fi
printf 'Hello, world!\n'
PROGRAM
chmod +x "$output"
MOCK
chmod +x "$WORK/bin/compiler"
for tool in gcc g++ mcs dmd ghc fpc mono python3 pdflatex lualatex pdftotext; do
  ln -s compiler "$WORK/bin/$tool"
done

cd "$WORK/current"
for scenario in success compile_failure runtime_failure wrong_output python_failure pdf_failure pdf_wrong_output; do
  status=0
  SCENARIO="$scenario" PATH="$WORK/bin:$PATH" TMPDIR="$WORK/tmp" \
    bash "$ROOT/compilers/test.sh" > "$WORK/output" 2>&1 || status=$?
  if [[ "$scenario" == success ]]; then
    if [[ "$status" != 0 ]]; then
      cat "$WORK/output"
      printf 'FAIL %s: expected exit 0, got %s\n' "$scenario" "$status"
      exit 1
    fi
    for language in C C++ 'C#' D Haskell Pascal Python pdfLaTeX LuaLaTeX; do
      if ! grep -Fxq "PASS $language" "$WORK/output"; then
        cat "$WORK/output"
        printf 'FAIL %s: no result for %s\n' "$scenario" "$language"
        exit 1
      fi
    done
  elif [[ "$status" == 0 ]]; then
    cat "$WORK/output"
    printf 'FAIL %s: the runner accepted a bad result\n' "$scenario"
    exit 1
  fi
  expected_message=
  case "$scenario" in
    compile_failure) expected_message='FAIL: gcc failed.' ;;
    runtime_failure) expected_message='Runtime diagnostic.' ;;
    wrong_output|pdf_wrong_output) expected_message='Wrong text' ;;
  esac
  if [[ -n "$expected_message" ]] && ! grep -Fxq "$expected_message" "$WORK/output"; then
    cat "$WORK/output"
    printf 'FAIL %s: no diagnostic text\n' "$scenario"
    exit 1
  fi
  if [[ -n "$(find "$WORK/tmp" -mindepth 1 -print -quit)" ]]; then
    printf 'FAIL %s: temporary files remain\n' "$scenario"
    exit 1
  fi
  if [[ -n "$(find "$WORK/current" -mindepth 1 -print -quit)" ]]; then
    printf 'FAIL %s: the runner wrote to the current directory\n' "$scenario"
    exit 1
  fi
  printf 'PASS compilers %s\n' "$scenario"
done

cat > "$WORK/fail-runner.sh" <<'MOCK'
#!/usr/bin/env bash
printf 'PASS C\nWrapper diagnostic.\n'
exit 27
MOCK
chmod +x "$WORK/fail-runner.sh"
sed "s|/x/test.sh|$WORK/fail-runner.sh|" "$ROOT/compilers/smoke-test.sh" > "$WORK/smoke-test.sh"
status=0
bash "$WORK/smoke-test.sh" > "$WORK/output" 2>&1 || status=$?
if [[ "$status" != 27 ]] || ! grep -Fxq 'PASS C' "$WORK/output" || \
    ! grep -Fxq 'Wrapper diagnostic.' "$WORK/output"; then
  cat "$WORK/output"
  printf 'FAIL wrapper_failure: the smoke test lost the result or diagnostic text\n'
  exit 1
fi
printf 'PASS compilers wrapper_failure\n'
