#! /bin/bash

cp -r summary summary.NF

nf=` head -1 summary/root/*reldiff | head -2 | tail -1 | awk '{print NF}' `

for i in summary/*/*; do
	sed 's/NA\([^\t ]\)/NA\t\1/g' -i $i 
	cat $i | awk -v nf="$nf" '{if(NF!=nf){print}}'
	awk -v nf="$nf" '{if(NF==nf){print}}' $i | sponge $i
done
