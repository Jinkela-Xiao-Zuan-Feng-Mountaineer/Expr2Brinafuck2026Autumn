#!/bin/sh
set -eu
cd "$(dirname "$0")"
compiler=${1:-./exprc}
runner=${2:-../BrainfuckRunner/bf}
maxstep=${MAXSTEP:-1000000000}
tmp=$(mktemp -d)
trap 'rm -f "$tmp/code" "$tmp/out" "$tmp/err" "$tmp/actual"; rmdir "$tmp"' 0
trap 'exit 1' HUP INT TERM
passed=0
for source in benchmarks/cases/*.expr; do
    name=$(basename "$source" .expr)
    if ! "$compiler" "$source" > "$tmp/code" 2> "$tmp/err"; then
        printf 'FAIL %s: compilation failed\n' "$name"
        cat "$tmp/err"
        exit 1
    fi
    if ! "$runner" "$tmp/code" "$maxstep" < "benchmarks/cases/$name.in" > "$tmp/out" 2> "$tmp/err"; then
        printf 'FAIL %s: execution failed\n' "$name"
        cat "$tmp/err"
        exit 1
    fi
    tr -d '\r' < "$tmp/out" > "$tmp/actual"
    if ! cmp -s "$tmp/actual" "benchmarks/cases/$name.expected"; then
        printf 'FAIL %s: incorrect output\n' "$name"
        diff "benchmarks/cases/$name.expected" "$tmp/actual" || :
        exit 1
    fi
    passed=$((passed + 1))
    printf 'PASS %s: ' "$name"
    cat "$tmp/err"
done
printf 'All %s cases passed.\n' "$passed"
