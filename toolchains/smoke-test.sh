#!/usr/bin/env bash
# Compile and run a Hello world program in each language of the image.
# The test is offline. It checks each program output and stops at the first failure.
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
export GOCACHE="$work/go-cache"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Print the output of a command and compare it with the expected text.
expect_output() {
    local expected=$1
    shift
    local actual
    actual=$("$@")
    [[ "$actual" == "$expected" ]] || fail "$* printed '$actual', expected '$expected'"
    echo "OK: $expected"
}

cat > hello.cpp <<'SRC'
#include <iostream>
int main() { std::cout << "cpp-ok" << std::endl; }
SRC
g++ -o hello_cpp hello.cpp
expect_output cpp-ok ./hello_cpp

cat > Hello.java <<'SRC'
public class Hello { public static void main(String[] args) { System.out.println("java-ok"); } }
SRC
javac Hello.java
expect_output java-ok java -cp . Hello

expect_output node-ok node -e 'console.log("node-ok")'
expect_output python-ok python3 -c 'print("python-ok")'
expect_output perl-ok perl -e 'print "perl-ok\n"'
expect_output php-ok php -r 'echo "php-ok\n";'
expect_output ruby-ok ruby -e 'puts "ruby-ok"'

cat > hello.go <<'SRC'
package main

import "fmt"

func main() { fmt.Println("go-ok") }
SRC
expect_output go-ok go run hello.go

echo "All toolchains run their Hello world programs."
