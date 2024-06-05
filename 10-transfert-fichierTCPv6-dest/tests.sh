#!/bin/bash

PROG="./receiver-tcp"
FILE="$PROG.c"

PORT=`shuf -i 10000-65000 -n 1`

OUT="/tmp/$$"
mkdir $OUT

IP="::1"

######################################

echo -n "test 01 - program usage: "

echo "usage: $PROG ip_addr port_number" > $OUT/usage
$PROG > $OUT/stdout 2> $OUT/stderr         && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr            && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"                                && exit 1

$PROG a > $OUT/stdout 2> $OUT/stderr       && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr            && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"                                && exit 1

$PROG a b c > $OUT/stdout 2> $OUT/stderr     && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr            && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"                                && exit 1

echo "...............OK"

######################################

echo -n "test 02 - no dynamic memory allocation: "

grep -q "[cm]alloc" $FILE && echo "KO -> dynamic memory allocation is not allowed!" && exit 1

echo "OK"

######################################

echo -n "test 03 - invalid port number: "

$PROG a 65001 > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

$PROG a 9999 > $OUT/stdout 2> $OUT/stderr  && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

echo ".........OK"

######################################

echo -n "test 04 - error on getaddrinfo: "

nc -n fdjkfslkfj 80 > /dev/null 2> $OUT/error
ERROR=$(grep -o '\S*$' $OUT/error)

$PROG fdjkfslkfj $PORT > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $?"            && exit 1
[ -s $OUT/stdout ]                                  && echo "KO -> output detected on stdout" && exit 1

STUDENT=$(grep -o '\S*$' $OUT/stderr)
[ "$ERROR" != "$STUDENT" ] && echo "KO -> unexpected output on stderr, use gai_strerror whenever getaddrinfo fails" && exit 1

echo "........OK"

######################################

echo -n "test 05 - program exits without error: "

timeout 10 $PROG $IP $PORT > $OUT/stdout 2> $OUT/stderr &
TO=$!
sleep 5
timeout 1 nc -6 $IP $PORT < receiver-tcp &
wait $!
wait $TO
R=$?

[ "$R" == "124" ]  && echo "KO -> program times out"           && exit 1
[ "$R" != "0" ]    && echo "KO -> exit status $R instead of 0" && exit 1
[ -s $OUT/stderr ] && echo "KO -> output detected on stdout"   && exit 1
[ -s $OUT/stderr ] && echo "KO -> output detected on stderr"   && exit 1

echo ".OK"

######################################

echo -n "test 06 - file copy.tmp exists: "

[ ! -f "copy.tmp" ] && echo "KO -> file does not exist" && exit 1

echo "........OK"

######################################

echo -n "test 07 - files are the same: "

! cmp -s receiver-tcp copy.tmp 2> /dev/null && echo "KO -> files differ" && exit 1

echo "..........OK"

######################################

echo -n "test 08 - check bind failure: "

timeout 5 nc -6l ::1 $PORT &
TO=$!
sleep 1

$PROG $IP $PORT > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1 
wait $TO
[ -s $OUT/stdout ]   && echo "KO -> output detected on stdout"     && exit 1
! [ -s $OUT/stderr ] && echo "KO -> no output detected on stderr"  && exit 1

echo "..........OK"

######################################

echo -n "test 09 - check open failure: "

chmod 000 copy.tmp
$PROG $IP $PORT > $OUT/stdout 2> $OUT/stderr &
PID=$!
sleep 5
timeout 1 nc -6 $IP $PORT < receiver-tcp
wait $PID
R=$?

[ "$R" != "1" ]      && echo "KO -> exit status $R instead of 1"  && exit 1
[ -s $OUT/stdout ]   && echo "KO -> output detected on stdout"    && exit 1
! [ -s $OUT/stderr ] && echo "KO -> no output detected on stderr" && exit 1

chmod 644 copy.tmp

echo "..........OK"

######################################

echo -n "test 10 - memory error: "

P=`which valgrind`
[ -z "$P" ] && echo "KO -> please install valgrind" && exit 1

valgrind --leak-check=full --error-exitcode=100 --log-file=$OUT/valgrind.log $PROG $IP $PORT > /dev/null &
V=$!
sleep 5
cat receiver-tcp | nc -6 -w1 ::1 $PORT
wait $V
[ "$?" == "100" ] && echo "KO -> memory pb please check valgrind.log" && exit 1

echo "................OK"

######################################

rm -r $OUT
