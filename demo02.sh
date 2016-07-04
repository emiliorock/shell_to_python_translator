#!/bin/bash

# read from standard imput
# check if the number is perfect or not

echo "Enter a number and I will check if it is perfect or not"  
read number  # read the number from standard input

i=1  

sum=0  

while [ $i -le `expr $number / 2` ]  ###   
   do
       if [ `expr $number % $i` -eq 0 ]   ### if i is a factor of number
       then
          sum=`expr $sum + $i`
       fi
       i=`expr $i + 1`
done
if [ $number -eq $sum ]
then
	echo "$number is perfect"
else
	echo "$number is NOT perfect"
fi
