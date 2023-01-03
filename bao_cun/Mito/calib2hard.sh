#! /bin/bash

infile=$1

line_1=`head -1 $infile`

line_2=`sed "1d; s/>\([0-9.]\+\)<\([0-9.]\+\)/\'B(\1,\2,0,0.025)\'/g" $infile`

echo $line_1
echo $line_2
