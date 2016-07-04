#!/bin/bash

# read the name from input
# read a number from input and sum up all the digits
# try date, id, pwd, ls command

echo "Hi!" 'What' "is your" "name?"
read name

echo "Hello $name : ) Try give me a number"
read num
temp=$num
n=0
sum=0
echo "The sum of all the digits in $temp is:"
while [ 0 -lt `expr $num / 10` ]
do
	n=`expr $num % 10`
	sum=`expr $sum + $n`
	num=`expr $num / 10`	
done
sum=`expr $sum + $num`
echo "$sum"

echo "See current time:[1]  Check id:[2]  Check pwd:[3]  List all files:[4]"
read word
if test $word -eq 1
then
	echo `date`
fi
if test $word -eq 2
then
	id
fi
if [ $word -eq 3 ]
then
	echo `pwd`
fi
if test $word -eq 4 
then
	ls
fi
