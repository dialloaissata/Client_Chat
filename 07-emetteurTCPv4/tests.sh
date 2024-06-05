#!/bin/bash

PROG="./sender-tcp"
FILE="$PROG.c"

PORT=`shuf -i 10000-65000 -n 1`

OUT="/tmp/$$"
mkdir $OUT

IP="127.0.0.1"

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

echo ".....................OK"

######################################

echo -n "test 02 - no dynamic memory allocation: "

grep -q "[cm]alloc" $FILE && echo "KO -> dynamic memory allocation is not allowed!" && exit 1

echo "......OK"

######################################

echo -n "test 03 - invalid port number: "

$PROG a 65001 > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

$PROG a 9999  > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1
! [ -s $OUT/stderr ]                       && echo "KO -> no output on stderr"         && exit 1
[ -s $OUT/stdout ]                         && echo "KO -> output detected on stdout"   && exit 1

echo "...............OK"

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

echo ".................OK"

######################################

echo -n "test 05 - check connect error: "

LC_ALL=C $PROG $IP 23451 > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1" && exit 1

ERROR="Connection refused"
! grep -q "$ERROR" $OUT/stderr                      && echo "KO -> unexpected output on stderr, do you use perror?" && exit 1
[ -s $OUT/stdout ]                                  && echo "KO -> output detected on stdout"                       && exit 1

echo "...............OK"

######################################

echo -n "test 06 - use struct returned by getaddrinfo: "

grep -q "sockaddr_.*" $FILE && echo "KO -> you should not use struct sockaddrX variable" && exit 1

echo "OK"

######################################

echo -n "test 07 - program exits without error: "

timeout 10 nc -4l $IP $PORT > $OUT/msg_r &
sleep 4
! $PROG $IP $PORT > $OUT/stdin 2> $OUT/stderr && echo "KO -> exit status != 0"          && exit 1
[ -s $OUT/stderr ]                            && echo "KO -> output detected on stderr" && exit 1
[ -s $OUT/stdout ]                            && echo "KO -> output detected on stdout" && exit 1

echo ".......OK"

######################################

echo -n "test 08 - program sends a message: "

! [ -s $OUT/msg_r ] && echo "KO -> no message transmitted" && exit 1

echo "...........OK"

######################################

echo -n "test 09 - message is valid: "

printf "hello world" > $OUT/msg_o
! cmp -s $OUT/msg_o $OUT/msg_r && echo "KO -> check files \"$OUT/msg_o\" (expected) and \"$OUT/msg_r\" (sent)" && exit 1

echo "..................OK"

######################################

echo -n "test 10 - memory error: "

P=`which valgrind`
[ -z "$P" ] && echo "KO -> please install valgrind" && exit 1
timeout 10 nc -4l $IP $PORT > /dev/null &
sleep 4
valgrind --leak-check=full --error-exitcode=100 --log-file=$OUT/valgrind.log $PROG $IP $PORT
[ "$?" == "100" ] && echo "KO -> memory pb please check valgrind.log" && exit 1

echo "..................................OK"

rm -r $OUT
