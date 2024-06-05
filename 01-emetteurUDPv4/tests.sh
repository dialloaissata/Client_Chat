#!/bin/bash

PROG="./sender-udp"
PORT=`shuf -i 10000-65000 -n 1`

echo -n "test 01 - program without arg: "
$PROG > /dev/null 2>&1 && echo "KO -> exit status $? instead of 1" && exit 1 
echo "...........OK"

echo -n "test 02 - invalid port number: "
$PROG 65001 > /dev/null 2>&1 && echo "KO -> exit status $? instead of 1" && exit 1 
echo "...........OK"

echo -n "test 03 - program exits without error: "
timeout 5 nc -4ul 127.0.0.1 $PORT > output &
sleep 2
! $PROG $PORT 2> /dev/null && echo "KO -> exit status != 0" && exit 1
echo "...OK"

echo -n "test 04 - program sends a message: "
MES=`cat output`
[ -z "$MES" ] && echo "KO -> no message" && exit 1
echo ".......OK"

echo -n "test 05 - message is valid: "
[ "$MES" != "hello world" ] && echo "KO - received: $MES | expected: hello world" && exit 1
echo "..............OK"

echo -n "test 06 - memory error: "
P=`which valgrind`
[ -z "$P" ] && echo "KO -> please install valgrind" && exit 1
valgrind --leak-check=full --error-exitcode=100 --log-file=valgrind.log $PROG $PORT
[ "$?" == "100" ] && echo "KO -> memory pb please check valgrind.log" && exit 1
echo "..................OK"

rm output valgrind.log
