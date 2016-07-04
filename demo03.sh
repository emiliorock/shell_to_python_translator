#!/bin/bash

# read a sequence of numbers in command line argument
# for each number, check if it is the sum or the product 
# of another two numbers in the sequence

if [ $# -lt 3 ]
then
	echo "please give me at least 3 numbers"
	exit 1
fi

for i in "$@"  # check
do
	for j in "$@"
	do
		for k in "$@" 
		do
			if test $i -eq `expr $j + $k + 1 - 1` -a $j -ne $k
			then
				echo "$i is the sum of $j and $k"
			fi
			if test $i -eq `expr $j '*' $k` -a $j -ne $k -a $i -ne $j -a $i -ne $k
			then
				echo "$i is the product of $j and $k"
			fi
		done
	done
done
