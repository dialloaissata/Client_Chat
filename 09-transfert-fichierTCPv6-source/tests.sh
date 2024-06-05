#!/bin/bash

PROG="./sender-tcp"
FILE="$PROG.c"

PORT=`shuf -i 10000-65000 -n 1`

OUT="/tmp/$$"
mkdir $OUT

IP="::1"

SE=$(uname -s)

######################################

echo -n "test 01 - program usage: "

echo "usage: $PROG ip_addr port_number filename" > $OUT/usage
$PROG > $OUT/stdout 2> $OUT/stderr         && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr            && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"                                && exit 1

$PROG a > $OUT/stdout 2> $OUT/stderr       && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr            && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"                                && exit 1

$PROG a b > $OUT/stdout 2> $OUT/stderr     && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr            && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"                                && exit 1

$PROG a b c d > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr            && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"                                && exit 1

echo ".......................OK"

######################################

echo -n "test 02 - no dynamic memory allocation: "

grep -q "[cm]alloc" $FILE && echo "KO -> dynamic memory allocation is not allowed!" && exit 1

echo "........OK"

######################################

echo -n "test 03 - invalid port number: "

$PROG a 65001 file > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                            && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                              && echo "KO -> output detected on stdout"   && exit 1

$PROG a 9999  file > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                            && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                              && echo "KO -> output detected on stdout"   && exit 1

echo ".................OK"

######################################

echo -n "test 04 - program with unknown filename: "

$PROG $IP $PORT abcd > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1 
! [ -s $OUT/stderr ]                              && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                                && echo "KO -> output detected on stdout"   && exit 1

echo ".......OK"

######################################

echo -n "test 05 - getaddrinfo usage: "

ERROR="Name or service not known"
if [ "$SE" == "Darwin" ]; then
    ERROR="nodename nor servname provided, or not known"
fi

LC_ALL=C $PROG a $PORT README.md > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1"                              && exit 1
! grep -q "$ERROR" $OUT/stderr                                && echo "KO -> unexpected output on stderr, you should use gai_strerror" && exit 1
grep -q "$ERROR" $FILE                                        && echo "KO -> no static msg for getaddrinfo error"                      && exit 1
[ -s $OUT/stdout ]                                            && echo "KO -> output detected on stdout"                                && exit 1

echo "...................OK"

######################################

echo -n "test 06 - connection to a non listening server: "

$PROG $IP $PORT $PROG > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $?"            && exit 1 
[ -s $OUT/stdout ]                                 && echo "KO -> output detected on stdout" && exit 1
! [ -s $OUT/stderr ]                               && echo "KO -> no output on stderr"       && exit 1

echo "OK"

######################################

echo -n "test 07 - program exits without error: "

timeout 10 nc -6l $IP $PORT > $OUT/copy.tmp &
TO=$!
sleep 4
! $PROG $IP $PORT $PROG > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $?"            && exit 1
wait $TO
[ -s $OUT/stderr ]                                   && echo "KO -> output detected on stderr" && exit 1

echo ".........OK"

######################################

echo -n "test 08 - program sent some data: "

! [ -s $OUT/copy.tmp ] && echo "KO -> no data (empty file at the receiver)" && exit 1

echo "..............OK"

######################################

echo -n "test 09 - files are the same: "

! cmp -s $PROG $OUT/copy.tmp && echo "KO -> files differ, check \"$PROG\" (transmitted) and \"$OUT/copy.tmp\" (received)" && exit 1

echo "..................OK"

######################################

echo -n "test 10 - execution time: "

head -c 1024300 /dev/urandom > $OUT/toto_b

timeout 10 nc -6l $IP $PORT > $OUT/copy.tmp &
TO=$!
sleep 4

t0=`date +%s`
$PROG $IP $PORT $OUT/toto_b > $OUT/stdout 2> $OUT/stderr
t1=`date +%s`
runtime=$(($t1 - $t0))
[ $runtime -gt "1" ] && echo "KO -> execution time exceeds 1sec., you should read by blocks" && exit 1
[ -s $OUT/stdout ]   && echo "KO -> output detected on stdout"                               && exit 1
[ -s $OUT/stderr ]   && echo "KO -> output detected on stderr"                               && exit 1

wait $TO

echo "......................OK"

######################################

echo -n "test 11 - memory error: "

P=`which valgrind`
[ -z "$P" ] && echo "KO -> please install valgrind" && exit 1
timeout 10 nc -6l $IP $PORT > $OUT/copy.tmp &
sleep 4

valgrind --leak-check=full --error-exitcode=100 --log-file=$OUT/valgrind.log $PROG $IP $PORT $OUT/toto_b > /dev/null 2>&1
[ "$?" == "100" ] && echo "KO -> memory pb please check $OUT/valgrind.log" && exit 1

echo "........................OK"

######################################

rm -r $OUT
