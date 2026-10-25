#!/usr/bin/env bash
# Compile each example and check its result.
set -euo pipefail

source_dir=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

compile() {
    if "$@" > build.log 2>&1; then
        return
    fi
    cat build.log >&2
    printf 'FAIL: %s failed.\n' "$1" >&2
    return 1
}

check_result() {
    local language=$1 output status=0
    shift
    printf '== Program in %s ==\n' "$language"
    output=$("$@") || status=$?
    printf '%s\n' "$output"
    if ((status != 0)); then
        printf 'FAIL %s: the program failed.\n' "$language" >&2
        return "$status"
    fi
    if [[ "$output" != 'Hello, world!' ]]; then
        printf 'FAIL %s: expected Hello, world!\n' "$language" >&2
        return 1
    fi
    printf 'PASS %s\n' "$language"
}

compile gcc "$source_dir/hw_c.c" -o hello_c
check_result C ./hello_c

compile g++ "$source_dir/hw_cpp.cpp" -o hello_cpp
check_result C++ ./hello_cpp

compile mcs -out:hello_csharp.exe "$source_dir/hw.cs"
check_result 'C#' mono hello_csharp.exe

compile dmd -of=hello_d "$source_dir/hw_d.d"
check_result D ./hello_d

compile ghc -outputdir "$work" -o hello_haskell "$source_dir/hw_haskell.hs"
check_result Haskell ./hello_haskell

compile fpc -FE"$work" -FU"$work" -ohello_pascal "$source_dir/hw_pascal.pas"
check_result Pascal ./hello_pascal

check_result Python python3 "$source_dir/hw_python.py"

compile pdflatex -interaction=nonstopmode -halt-on-error -jobname=hello_pdflatex "$source_dir/hw_latex.tex"
check_result pdfLaTeX pdftotext -nopgbrk hello_pdflatex.pdf -

# Keep the LuaLaTeX font cache inside the temporary directory.
export TEXMFCACHE="$work/texmf-cache"
export TEXMFVAR="$TEXMFCACHE"
mkdir -p "$TEXMFCACHE"
compile lualatex -interaction=nonstopmode -halt-on-error -jobname=hello_lualatex "$source_dir/hw_latex.tex"
check_result LuaLaTeX pdftotext -nopgbrk hello_lualatex.pdf -
