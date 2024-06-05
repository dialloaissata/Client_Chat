#!/bin/bash

PROG="./sender-udp"
PORT=`shuf -i 10000-65000 -n 1`

OUT="/tmp/$$"
mkdir $OUT

IP="::1"

######################################

echo -n "test 01 - program without arg: "

echo "usage: $PROG ip_addr port_number" > $OUT/usage
$PROG > $OUT/stdout 2> $OUT/stderr       && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr          && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                       && echo "KO -> output detected on stdout"                                && exit 1

$PROG a > $OUT/stdout 2> $OUT/stderr     && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr          && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                       && echo "KO -> output detected on stdout"                                && exit 1

$PROG a b c > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr          && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                       && echo "KO -> output detected on stdout"                                && exit 1

echo "........OK"

######################################

echo -n "test 02 - invalid port number: "

$PROG a 65001 > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

$PROG a 9999  > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

echo "........OK"

######################################

echo -n "test 03 - getaddrinfo usage: "

ERROR="Name or service not known"
LC_ALL=C $PROG a $PORT > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1"                           && exit 1
! grep -q "$ERROR" $OUT/stderr                      && echo "KO -> unexpected output on stderr, do you use gai_strerror?" && exit 1
[ -s $OUT/stdout ]                                  && echo "KO -> output detected on stdout"                             && exit 1

echo "..........OK"

######################################

echo -n "test 04 - program exits without error: "

timeout 5 nc -6ul $IP $PORT > $OUT/msg_r &
sleep 2
! $PROG $IP $PORT > $OUT/stdin 2> $OUT/stderr && echo "KO -> exit status != 0"          && exit 1
[ -s $OUT/stderr ]                            && echo "KO -> output detected on stderr" && exit 1
[ -s $OUT/stdout ]                            && echo "KO -> output detected on stdout" && exit 1

echo "OK"

######################################

echo -n "test 05 - program sends a message: "

! [ -s $OUT/msg_r ] && echo "KO -> no message received (stdout empty)" && exit 1

echo "....OK"

######################################

echo -n "test 06 - message is valid: "

printf "hello world" > $OUT/msg_o
! cmp -s $OUT/msg_o $OUT/msg_r && echo "KO -> check files \"$OUT/msg_o\" (expected) and \"$OUT/msg_r\" (sent)" && exit 1

echo "...........OK"


######################################

echo -n "test 07 - memory error: "

P=`which valgrind`
[ -z "$P" ] && echo "KO -> please install valgrind" && exit 1
valgrind --leak-check=full --error-exitcode=100 --log-file=$OUT/valgrind.log $PROG $IP $PORT
[ "$?" == "100" ] && echo "KO -> memory pb please check valgrind.log" && exit 1

echo "...............OK"

rm -r $OUT
