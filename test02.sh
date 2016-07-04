#!/bin/bash

a=1
b=2
c=3
a=`expr 1 + 1`
a=`expr 5 '*' 5`
a=`expr $5 '/' $c`
a=`expr $c - $b`
echo `expr 1 '*' 10`
echo `expr $a + 1`
echo `expr $a + $b`
c=`expr $a + 1`
echo $c 
c=`expr $a '*' $b`
echo $c