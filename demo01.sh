#!/bin/bash

# test if the specified integer is prime

if test $# != 1
then
    echo "Please" 'give' "a number to me, I wil test if it is a prime or not"  #should specify a number in the command line
    exit 1
fi

n=$1

i=2

while test $i -lt $n
do
    if test `expr $n % $i` -eq 0  ### if the number can be divided
    then
        echo "$n is not prime"
        exit 1
    fi
    i=`expr $i + 1`
done
echo "$n is prime"
