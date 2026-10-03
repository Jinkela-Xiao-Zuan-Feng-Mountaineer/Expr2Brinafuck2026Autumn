#!/bin/sh
set -eu
cd "$(dirname "$0")"
bf=${1:-./bf}
tmp=$(mktemp -d)
trap 'rm -f "$tmp/source.bf" "$tmp/out" "$tmp/err" "$tmp/expected" "$tmp/actual"; rmdir "$tmp"' 0
trap 'exit 1' HUP INT TERM
passed=0

# name, source, stdin, expected stdout, step count or error fragment, [maxstep]
check() {
    name=$1 code=$2 input=$3 output=$4 expected=$5
    shift 5
    printf '%s' "$code" > "$tmp/source.bf"
    status=0
    printf '%s' "$input" | "$bf" "$tmp/source.bf" "$@" > "$tmp/out" 2> "$tmp/err" || status=$?
    printf '%b' "$output" > "$tmp/expected"
    tr -d '\r' < "$tmp/out" > "$tmp/actual"
    if ! cmp -s "$tmp/expected" "$tmp/actual"; then
        printf 'FAIL %s: unexpected stdout\n' "$name"
        exit 1
    fi
    case "$expected" in
        *[!0-9]*)
            if [ "$status" -eq 0 ] || ! grep -F "$expected" "$tmp/err" > /dev/null; then
                printf 'FAIL %s: expected error %s\n' "$name" "$expected"
                cat "$tmp/err"
                exit 1
            fi ;;
        *)
            diagnostic=$(tr -d '\r' < "$tmp/err")
            if [ "$status" -ne 0 ] || [ "$diagnostic" != "Executed instructions: $expected" ]; then
                printf 'FAIL %s: unexpected status/count\n' "$name"
                cat "$tmp/err"
                exit 1
            fi ;;
    esac
    passed=$((passed + 1))
    printf 'PASS %s\n' "$name"
}

check empty '' '' '' 0
check comments 'hello world' '' '' 0
check zero '.' '' '0\n' 1
check wraparound '-.+.' '' '255\n0\n' 4
check cells '+>++.<.' '' '2\n1\n' 7
check skip '[+[+]-].' '' '0\n' 2
check loop '+++[-].' '' '0\n' 11
check nested '++[>++[>+<-]<-]>>.' '' '4\n' 40
check integers ',.,.,.,.' '-1 256 +42 511' '255\n0\n42\n255\n' 8
check left '<' '' '' 'left memory boundary'
moves=$(awk 'BEGIN { for (i=0; i<1048575; ++i) printf ">" }')
check last-cell "$moves+." '' '1\n' 1048577
check right "$moves>" '' '' 'right memory boundary'
check opening '.[' '' '' "unmatched '['"
check closing ']' '' '' "line 1, column 1: unmatched ']'"
check skipped-syntax '[[]' '' '' "unmatched '['"
check eof ',' '' '' 'input exhausted'
check invalid-input ',' '12x' '' 'decimal int'
check sign-only ',' '-' '' 'decimal int'
check input-overflow ',' '99999999999999999999' '' 'int range'
check exact-limit '+++[-].' '' '0\n' 11 11
check before-output '+++[-].' '' '' 'executed: 10' 10
check infinite '+[]' '' '' 'maxstep exceeded' 100
check zero-empty '' '' '' 0 0
check zero-comments 'hello' '' '' 0 0
check zero-nonempty '.' '' '' 'executed: 0' 0
check before-input ',' '' '' 'maxstep exceeded' 0
check partial-output '..' '' '0\n' 'maxstep exceeded' 1
check skip-limit '[+++].' '' '0\n' 2 2
check max-uint '.' '' '0\n' 1 18446744073709551615
check negative-limit '' '' '' 'non-negative decimal integer' -1
check malformed-limit '' '' '' 'non-negative decimal integer' 12x
check empty-limit '' '' '' 'non-negative decimal integer' ''
check overflow-limit '' '' '' 'uint64 range' 18446744073709551616
printf 'All %s tests passed.\n' "$passed"
