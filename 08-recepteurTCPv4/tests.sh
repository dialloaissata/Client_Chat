#!/bin/bash

PROG="./receiver-tcp"
FILE="$PROG.c"

PORT=`shuf -i 10000-65000 -n 1`
PORT_C=`shuf -i 10000-65000 -n 1`
IP="127.0.0.1"

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

echo -n "test 02 - no dynamic memory allocation: "

grep -q "[cm]alloc" $FILE && echo "KO -> dynamic memory allocation is not allowed!" && exit 1

echo ".....OK"

######################################

echo -n "test 03 - invalid port number: "

$PROG a 65001 > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

$PROG a 9999  > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

echo "..............OK"

######################################

echo -n "test 04 - getaddrinfo usage: "

ERROR="Name or service not known"
if [ "$SE" == "Darwin" ]; then
    ERROR="nodename nor servname provided, or not known"
fi

LC_ALL=C $PROG a $PORT > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1"                              && exit 1
! grep -q "$ERROR" $OUT/stderr                      && echo "KO -> unexpected output on stderr, you should use gai_strerror" && exit 1
grep -q "$ERROR" $FILE                              && echo "KO -> no static msg for getaddrinfo error"                      && exit 1
[ -s $OUT/stdout ]                                  && echo "KO -> output detected on stdout"                                && exit 1

echo "................OK"

######################################

echo -n "test 05 - check bind failure: "

timeout 10 nc -4l $IP $PORT > /dev/null 2>&1 &
TO=$!
sleep 4
LC_ALL=C timeout 5 $PROG $IP $PORT > $OUT/stdout 2> $OUT/stderr
R="$?"
[ "$R" == "124" ] && echo "KO -> program times out"           && exit 1
[ "$R" != "1" ]   && echo "KO -> exit status $R instead of 1" && exit 1
wait $!

ERROR="Address already in use"
! grep -q "$ERROR" $OUT/stderr && echo "KO -> unexpected output on stderr, you should use perror" && exit 1
grep -q "$ERROR" $FILE         && echo "KO -> no static msg for bind error"                       && exit 1
[ -s $OUT/stdout ]             && echo "KO -> output detected on stdout"                          && exit 1

echo "...............OK"

######################################

echo -n "test 06 - sender info in sockaddr_storage: "

! grep -q "sockaddr_storage" $FILE && echo "KO -> sockaddr_storage not found" && exit 1
grep -q "sockaddr_in"        $FILE && echo "KO -> remove sockaddr_in"         && exit 1

echo "..OK"

######################################

echo -n "test 07 - program exits without error: "

timeout 10 $PROG $IP $PORT > $OUT/stdout 2> $OUT/stderr &
TO=$!
sleep 4
timeout 1 echo "hello world" | nc -4 $IP $PORT -p $PORT_C
wait $TO
R=$?
[ "$R" == "124" ]  && echo "KO -> program times out"           && exit 1
[ "$R" != "0" ]    && echo "KO -> exit status $R instead of 0" && exit 1
[ -s $OUT/stderr ] && echo "KO -> output detected on stderr"   && exit 1

echo "......OK"

######################################

echo -n "test 08 - program prints sender IP and port: "

PRINTEDIP=`cat $OUT/stdout | head -n 1`
[ -z "$PRINTEDIP" ] && echo "KO -> nothing on stdout" && exit 1

echo "OK"

######################################

echo -n "test 09 - printed IP is valid: "

PRINTEDIP=`cat $OUT/stdout | head -n 1 | cut -d ' ' -f1`
[ "$PRINTEDIP" != "$IP" ] && echo "KO -> printed IP: $PRINTEDIP | expected: $IP" && exit 1

echo "..............OK"

######################################

echo -n "test 10 - printed PORT is valid: "

PRINTEDPORT=`cat $OUT/stdout | head -n 1 | cut -d ' ' -f2`
[ "$PRINTEDPORT" != "$PORT_C" ] && echo "KO -> printed PORT: $PRINTEDPORT | expected: $PORT_C" && exit 1

echo "............OK"

######################################

echo -n "test 11 - program received a message: "

NB=`cat $OUT/stdout | wc -l | tr -s ' ' | cut -d ' ' -f2`
[ "$NB" != "2" ] && echo "KO -> no message received" && exit 1

echo ".......OK"

######################################

echo -n "test 12 - received message is valid: "

MES=`cat $OUT/stdout | tail -1`
[ "$MES" != "hello world" ] && echo "KO -> message received: $MES | expected: hello world" && exit 1

echo "........OK"

######################################

echo -n "test 13 - program accept up to SIZE bytes: "

! grep -q "#define SIZE" $FILE && echo "KO -> no SIZE defined" && exit 1
SIZE=$(grep "#define SIZE" receiver-tcp.c | tr '\t' ' ' | tr -s ' ' | cut -d ' ' -f3)
LC_ALL=C tr -dc "A-Za-z0-9" < /dev/urandom | head -c $SIZE > $OUT/toto

timeout 5 $PROG $IP $PORT > $OUT/stdout 2> $OUT/stderr &
TO=$!
sleep 2
nc -4 $IP $PORT < $OUT/toto
wait $TO
R=$?

[ "$R" == "124" ]  && echo "KO -> program times out"           && exit 1
[ "$R" != "0" ]    && echo "KO -> exit status $R instead of 0" && exit 1
[ -s $OUT/stderr ] && echo "KO -> output detected on stderr"   && exit 1

NB=$(tail -1 $OUT/stdout | wc -c | tr -s ' '  | cut -d ' ' -f2)
[ "$NB" != "$SIZE" ] && echo "KO -> only \"$NB\"  bytes printed (\"$SIZE\" expected)" && exit 1

echo "..OK"

######################################

echo -n "test 14 - memory error: "

P=`which valgrind`
[ -z "$P" ] && echo "KO -> please install valgrind" && exit 1

LC_ALL=C tr -dc "A-Za-z0-9" < /dev/urandom | head -c 2049 > $OUT/toto

valgrind --leak-check=full --error-exitcode=100 --log-file=$OUT/valgrind.log $PROG $IP $PORT > /dev/null &
V=$!
sleep 3

nc -4 -w1 $IP $PORT < $OUT/toto
wait $V
[ "$?" == "100" ] && echo "KO -> memory pb please check valgrind.log" && exit 1

echo ".....................OK"

rm -r $OUT
