#! /bin/env bash

################################################################
treefile=''
boottrees=''
root=''


################################################################
while [ $# -gt 0 ]; do
	case $1 in
		-t)
			treefile=$2
			shift
			;;
		--bt|--boottrees)
			boottrees=$2
			shift
			;;
		--root)
			root=$2
			root=`sed "s/,/ /g" <<< $root`
			shift
			;;
	esac
	shift
done


################################################################
echo "convert to chronogram with convert2chronogram.R"
Rscript ~/project/Rhizobiales/scripts/angst/convert2chronogram.R $treefile |sed '$!d; s/\[1\] "//; s/"//' > data/substitution.tree

echo "parsing boottrees"
nw_topology -Ib $boottrees > output/alignment.fasta.trees

echo "rerooting"
nw_reroot output/alignment.fasta.trees $root | nw_topology -Ib - | sponge output/alignment.fasta.trees

echo "formatting alignment.fasta.trees"
awk 'BEGIN{OFS="\t"}{if(NR==1){print "Iteration","Posterior","Likelihood","Prior","psi"} else{a=NR-1; print a,a,a,a,$0}}' output/alignment.fasta.trees | sponge output/alignment.fasta.trees

echo -e "\e[31mNote that the time scale in substitution.tre needs to be changed!\e[30m"

