#!/bin/sh
set -eu
cd "$(dirname "$0")"
compiler=${1:-./exprc}
runner=${2:-../BrainfuckRunner/bf}
tmp=$(mktemp -d)
trap 'rm -f "$tmp/source" "$tmp/code" "$tmp/out" "$tmp/err" "$tmp/actual" "$tmp/expected"; rmdir "$tmp"' 0
trap 'exit 1' HUP INT TERM
passed=0
check() {
    name=$1
    printf '%b' "$2" > "$tmp/source"
    if ! "$compiler" "$tmp/source" > "$tmp/code" 2> "$tmp/err"; then
        printf 'FAIL %s: compilation failed\n' "$name"
        cat "$tmp/err"
        exit 1
    fi
    if ! printf '%s' "$3" | "$runner" "$tmp/code" 1000000000 > "$tmp/out" 2> "$tmp/err"; then
        printf 'FAIL %s: generated program failed\n' "$name"
        cat "$tmp/err"
        exit 1
    fi
    printf '%b' "$4" > "$tmp/expected"
    tr -d '\r' < "$tmp/out" > "$tmp/actual"
    if ! cmp -s "$tmp/expected" "$tmp/actual"; then
        printf 'FAIL %s\n' "$name"
        cat "$tmp/out"
        exit 1
    fi
    passed=$((passed + 1))
    printf 'PASS %s\n' "$name"
}
reject() {
    name=$1
    printf '%b' "$2" > "$tmp/source"
    if "$compiler" "$tmp/source" > "$tmp/code" 2> "$tmp/err"; then
        printf 'FAIL %s: accepted invalid source\n' "$name"; exit 1
    else
        status=$?
    fi
    if [ "$status" -ne 43 ]; then
        printf 'FAIL %s: expected exit code 43, got %s\n' "$name" "$status"
        cat "$tmp/err"
        exit 1
    fi
    if [ -s "$tmp/code" ] || [ ! -s "$tmp/err" ]; then
        printf 'FAIL %s: partial code or wrong diagnostic\n' "$name"; exit 1
    fi
    passed=$((passed + 1))
    printf 'PASS %s\n' "$name"
}
check example 'a=input()\nb=3+a*5\nprint(b)\nprint(a)\na=a+1\nprint(a)\nprint(0-a)' 4 '23\n4\n5\n251\n'
check precedence 'print(3+4*5)\nprint((3+4)*5)\nprint(10-3-2)\nprint(-3*2)\nprint(5--2)' '' '23\n35\n5\n250\n7\n'
check preservation 'a=input()\nb=a+a\nprint(a)\nprint(b)\na=a*(a+1)\nprint(a)\nprint(b)' 5 '5\n10\n30\n10\n'
check zero-products 'a=input()\nb=input()\nprint(a*b)\nprint(b*a)\nprint(b)\nprint(a)' '0 255' '0\n0\n255\n0\n'
check overflow 'print(255+1)\nprint(0-1)\nprint(255*255)\nprint(20*20)' '' '0\n255\n1\n144\n'
check nested-products 'a=3\nb=4\nprint((a*b)*(a+b))\nprint(a*a*a)\nprint(a)\nprint(b)' '' '84\n27\n3\n4\n'
check reassignment 'a=255\na=0\nprint(a)\na=input()\na=input()\nprint(a)\na=a\nprint(a)' '3 7' '0\n7\n7\n'
check unary 'a=5\nprint(--a)\nprint(+-+a)\nprint(-0)\nprint(+255)' '' '5\n251\n0\n255\n'
check lexical '# comment\r\n\t_A1 = 0007 # ignored !\r\na=2\r\nA=3\r\nprint (_A1+a+A)' '' '12\n'
check empty '' '' ''
check comments '# hi\n \t# bye\n' '' ''
check dead-inputs 'a=input()\na=input()\nb=input()\nprint(a)\nprint(b)' '13 29 255' '29\n255\n'
check effect-order 'a=input()\nprint(a+1)\nb=input()\nprint(a+1)\nprint(b)' '255 7' '0\n0\n7\n'
check alias-reassignment 'a=input()\nb=a\na=input()\nprint(b)\nprint(a)' '3 9' '3\n9\n'
check cse-reassignment 'a=input()\nb=a*7\na=a+1\nprint(a*7)\nprint(b)' '255' '0\n249\n'
check shared-subtraction 'a=input()\nb=input()\nc=a+b\nprint(c*c)\nprint(c-b)\nprint(c)' '129 130' '9\n129\n3\n'
check factorization 'a=input()\nprint(a*16*16)\nprint(a*7+a)\nprint(a*7-a*3)\nprint((a+200)+56)' '173' '0\n104\n180\n173\n'
check discarded-values 'a=input()\nb=a*a\n' '255' ''
check empty-effects 'a=3*7\nb=a*a\n' '' ''
# Test runtime values across the entire uint8 range against arithmetic computed by awk.
source=$(awk 'BEGIN { print "a=input()"; for(i=0;i<256;i++) { print "print(a+" i ")"; print "print(a-" i ")"; print "print(a*" i ")" } print "print(a)" }')
expected=$(awk 'BEGIN { for(i=0;i<256;i++) { print (173+i)%256; print (173-i+256)%256; print (173*i)%256 } print 173 }')
check all-byte-operands "$source" 173 "$expected\n"
reject undefined 'print(a)' 'undefined variable'
reject first-self-assignment 'a=a+1' 'undefined variable'
reject late-error 'a=1\nprint(a)\nprint(b)' 'line 3'
reject constant 'a=256' '0..255'
reject huge-constant 'a=999999999999999999999999' '0..255'
reject input-reserved 'input=3' 'line 1'
reject print-reserved 'print=3' 'line 1'
reject unbalanced 'a=(3+2' "expected ')'"
reject division 'a=3/2' 'unsupported character'
reject embedded-input 'a=input()+1' 'unexpected token'
reject print-input 'print(input())' 'reserved word'
reject input-args 'a=input(1)' "expected ')'"
reject print-empty 'print()' 'expected expression'
reject print-args 'print(1,2)' 'unsupported character'
reject two-statements 'a=1 b=2' 'unexpected token'
reject semicolon 'a=1;' 'unsupported character'
reject chained 'a=b=3' 'line 1'
reject split-expression 'a=1+\n2' 'line 1'
reject trailing-token 'print(1) 2' 'unexpected token'
reject hex 'a=0xff' 'unexpected token'
reject case-sensitive 'a=1\nprint(A)' 'undefined variable'
reject standalone-input 'input()'
reject parenthesized-input 'a=(input())'
reject missing-rhs 'a= # missing expression'
reject missing-operand 'print(1 +)'
reject extra-closing-paren 'print(1))'
reject numeric-identifier '1a=3'
reject float-constant 'a=1.5'
reject negative-out-of-range 'a=-256'
reject undefined-times-zero 'print(unknown * 0)'
reject late-syntax-error 'a=input()\nprint(a)\nb=(2+3'
printf 'All %s tests passed.\n' "$passed"
