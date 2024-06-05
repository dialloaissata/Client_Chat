#!/bin/bash

PROG="./receiver-udp"
FILE="$PROG.c"

PORT=`shuf -i 10000-30000 -n 1`
PORT_C=`shuf -i 30001-65000 -n 1`
IP="::1"

OUT="/tmp/$$"
mkdir $OUT

SE=$(uname -s)

######################################

echo -n "test 01 - program usage: "

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

echo "....................OK"

######################################

echo -n "test 02 - invalid port number: "

$PROG a 65001 > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

$PROG a 9999  > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

echo "..............OK"

######################################

echo -n "test 03 - getaddrinfo usage: "

ERROR="Name or service not known"
if [ "$SE" == "Darwin" ]; then
    ERROR="nodename nor servname provided, or not known"
fi

LC_ALL=C $PROG a $PORT > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1"                           && exit 1
! grep -q "$ERROR" $OUT/stderr                      && echo "KO -> unexpected output on stderr, do you use gai_strerror?" && exit 1
[ -s $OUT/stdout ]                                  && echo "KO -> output detected on stdout"                             && exit 1

echo "................OK"

######################################

echo -n "test 04 - check bind failure: "

timeout 8 nc -6ul $IP $PORT > /dev/null &
TO=$!
sleep 3
LC_ALL=C timeout 5 $PROG $IP $PORT > $OUT/stdout 2> $OUT/stderr
R="$?"
[ "$R" == "124" ] && echo "KO -> program times out"           && exit 1
[ "$R" != "1" ]   && echo "KO -> exit status $R instead of 1" && exit 1
wait $!

ERROR="Address already in use"
! grep -q "$ERROR" $OUT/stderr                      && echo "KO -> unexpected output on stderr, do you use perror?" && exit 1
[ -s $OUT/stdout ]                                  && echo "KO -> output detected on stdout"                       && exit 1

echo "...............OK"

######################################

echo -n "test 05 - program exits without error: "

timeout 5 $PROG $IP $PORT > $OUT/stdout 2> $OUT/stderr &
TO=$!
sleep 2
echo "hello world" | nc -6u -w1 $IP $PORT -p $PORT_C
wait $TO
R=$?
[ "$R" == "124" ]  && echo "KO -> program times out"           && exit 1
[ "$R" != "0" ]    && echo "KO -> exit status $R instead of 0" && exit 1
[ -s $OUT/stderr ] && echo "KO -> output detected on stdout"   && exit 1

echo "......OK"

######################################

echo -n "test 06 - program received a message: "

! [ -s $OUT/stdout ] && echo "KO -> no message received (stdout empty)" && exit 1

echo ".......OK"

######################################

echo -n "test 07 - message is valid: "

echo "hello world"  > $OUT/msg_e
head -1 $OUT/stdout > $OUT/msg_r
! cmp -s $OUT/msg_e $OUT/msg_r && echo "KO -> unexpected msg: check files \"$OUT/msg_e\" file and \"$OUT/msg_r\" (yours)" && exit 1

echo ".................OK"

######################################

echo -n "test 08 - program prints sender IP and port: "

NB=`cat $OUT/stdout | wc -l | tr -s ' ' | cut -d ' ' -f2`
[ "$NB" != "2" ] && echo "KO -> no output detected on stdout" && exit 1

echo "OK"

######################################

echo -n "test 09 - printed IP is valid: "

PRINTEDIP=`cat $OUT/stdout | tail -1 | cut -d ' ' -f1`
[ "$PRINTEDIP" != "$IP" ] && echo "KO -> printed IP: $PRINTEDIP | expected: $IP" && exit 1

echo "..............OK"

######################################

echo -n "test 10 - printed PORT is valid: "

PRINTEDPORT=`cat $OUT/stdout | tail -1 | cut -d ' ' -f2`
[ "$PRINTEDPORT" != "$PORT_C" ] && echo "KO -> printed PORT: $PRINTEDPORT | expected: $PORT_C" && exit 1

echo "............OK"

######################################

echo -n "test 11 - memory error: "

P=`which valgrind`
[ -z "$P" ] && echo "KO -> please install valgrind" && exit 1

LC_ALL=C tr -dc "A-Za-z0-9" < /dev/urandom | head -c 2048 > $OUT/toto

valgrind --leak-check=full --error-exitcode=100 --log-file=$OUT/valgrind.log $PROG $IP $PORT > /dev/null &
V=$!
sleep 4
nc -6u -w1 $IP $PORT < $OUT/toto
wait $V
[ "$?" == "100" ] && echo "KO -> memory pb please check $OUT/valgrind.log" && exit 1

echo ".....................OK"

rm -r $OUT
