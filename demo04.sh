#!/bin/bash

# read a number Num from standard input as the index of Fibonacci sequence
# give the first Num numbers of Fibonacci sequence

if [ $# -eq 1 ]
then
	Num=$1
else
	echo "How many Fibonacci numbers do you want?"
	read Num
fi

f1=0
f2=1

echo "The first $Num Fibonacci numbers are : "

i=0

while test $i -lt $Num
do
	echo "$f1"
     	fn=$(($f1 + $f2))
     	f1=$f2
	f2=$fn
 	i=`expr $i + 1`
done
