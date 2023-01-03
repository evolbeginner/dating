#! /bin/bash

infile=$1
species_file=$2

line_1=`head -1 $infile`

line_2=`sed "1d" $infile | nw_prune -vf - $species_file`

no_of_species=`echo $line_2 | nw_stats - | grep 'leaves'|cut -f 2`

echo -e "$no_of_species\t1"
echo $line_2

