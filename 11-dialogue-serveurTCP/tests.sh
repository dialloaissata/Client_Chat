#!/bin/bash

PROG="./client-http"
FILE="$PROG.c"

OUT="/tmp/$$"

mkdir $OUT

URL="mai-reseau-get.psi.ad.unistra.fr"
URL4="mai-reseau-get-v4.psi.ad.unistra.fr"
URL6="mai-reseau-get-v6.psi.ad.unistra.fr"

######################################

echo -n "test 01 - program without arg: "

echo "usage: $PROG server_name" > $OUT/usage
$PROG > $OUT/stdout 2> $OUT/stderr     && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr        && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                     && echo "KO -> output detected on stdout"                                && exit 1

$PROG a b > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $? instead of 1"                              && exit 1
! cmp -s $OUT/usage $OUT/stderr        && echo "KO -> unexpected output on stderr => check file \"$OUT/usage\"" && exit 1
[ -s $OUT/stdout ]                     && echo "KO -> output detected on stdout"                                && exit 1

echo ".............................OK"

######################################

echo -n "test 02 - no dynamic memory allocation: "

grep -q "[cm]alloc" $FILE && echo "KO -> dynamic memory allocation is not allowed!" && exit 1

echo "....................OK"

######################################

echo -n "test 03 - connection to a non existing server: "

nc fdjkfslkfj 80 > /dev/null 2> $OUT/error
ERROR=$(grep -o '\S*$' $OUT/error)

$PROG fdjkfslkfj > $OUT/stdout 2> $OUT/stderr && echo "KO -> exit status $?"                                    && exit 1
[ -s $OUT/stdout ]                            && echo "KO -> output detected on stdout"                         && exit 1
STUDENT=$(grep -o '\S*$' $OUT/stderr)
[ "$ERROR" != "$STUDENT" ]                    && echo "KO -> unexpected output on stderr, you should use gai_strerror when getaddrinfo fails" && exit 1

echo ".............OK"

######################################

echo -n "test 04 - program exits without error on IPv4 server: "

timeout 5 $PROG $URL4 > $OUT/stdout 2> $OUT/stderr
R=$?
[ "$R" == "124" ]  && echo "KO -> program times out"           && exit 1
[ "$R" != "0" ]    && echo "KO -> exit status $R instead of 0" && exit 1
[ -s $OUT/stderr ] && echo "KO -> output detected on stderr"   && exit 1

echo "......OK"

######################################

echo -n "test 05 - get a response from the IPv4 http server: "

! [ -s $OUT/stdout ] && echo "KO -> no output detected on stdout" && exit 1

echo "........OK"

######################################

echo -n "test 06 - IPv4 html response is valid: "

grep -v -e "Date" -e "Last-Modified" $OUT/stdout > $OUT/pg.http
echo -e "GET / HTTP/1.1\r\nHost: $URL4\r\nConnection:close\r\n\r\n" | nc -4 $URL4 80 > $OUT/nc-output
grep -v -e "Date" -e "Last-Modified" $OUT/nc-output > $OUT/legacy.http
! cmp -s $OUT/legacy.http $OUT/pg.http && echo "KO -> files differ" && exit 1

echo ".....................OK"

######################################

echo -n "test 07 - program exits without error on IPv6 server: "

timeout 5 $PROG $URL6 > $OUT/stdout 2> $OUT/stderr
R=$?
cat $OUT/stderr
[ "$R" == "124" ]  && echo "KO -> program times out"           && exit 1
[ "$R" != "0" ]    && echo "KO -> exit status $R instead of 0" && exit 1
[ -s $OUT/stderr ] && echo "KO -> output detected on stderr"   && exit 1

echo "......OK"

######################################

echo -n "test 08 - get a response from the IPv6 http server: "

! [ -s $OUT/stdout ] && echo "KO -> no output detected on stdout" && exit 1

echo "........OK"

######################################

echo -n "test 09 - IPv6 html response is valid: "

grep -v -e "Date" -e "Last-Modified" $OUT/stdout > $OUT/pg.http
echo -e "GET / HTTP/1.1\r\nHost: $URL6\r\nConnection:close\r\n\r\n" | nc -6 $URL6 80 > $OUT/output
grep -v -e "Date" -e "Last-Modified" $OUT/output > $OUT/legacy.http
! cmp -s $OUT/legacy.http $OUT/pg.http && echo "KO -> files differ" && exit 1

echo ".....................OK"

######################################

echo -n "test 10 - program exits without error on dual stack server: "

timeout 5 $PROG $URL > $OUT/stdout 2> $OUT/stderr
R=$?
[ "$R" == "124" ]  && echo "KO -> program times out"           && exit 1
[ "$R" != "0" ]    && echo "KO -> exit status $R instead of 0" && exit 1
[ -s $OUT/stderr ] && echo "KO -> output detected on stderr"   && exit 1

echo "OK"

######################################

echo -n "test 11 - get a response from the dual stack http server: "

! [ -s $OUT/stdout ] && echo "KO -> no output detected on stdout" && exit 1

echo "..OK"

######################################

echo -n "test 12 - dual stack html response is valid: "

grep -v -e "Date" -e "Last-Modified" $OUT/stdout > $OUT/pg.http
echo -e "GET / HTTP/1.1\r\nHost: $URL\r\nConnection:close\r\n\r\n" | nc -6 $URL 80 > $OUT/output
grep -v -e "Date" -e "Last-Modified" $OUT/output > $OUT/legacy.http
! cmp -s $OUT/legacy.http $OUT/pg.http && echo "KO -> files differ" && exit 1

echo "...............OK"

######################################

echo -n "test 13 - memory error: "

P=`which valgrind`
[ -z "$P" ] && echo "KO -> please install valgrind" && exit 1

valgrind --leak-check=full --error-exitcode=100 --log-file=$OUT/valgrind.log $PROG google.com > /dev/null 2>&1
[ "$?" == "100" ] && echo "KO -> memory pb please check file $OUT/valgrind.log" && exit 1
echo "....................................OK"

rm -r $OUT
