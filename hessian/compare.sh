#! /bin/bash


######################################################
range=(10 20 30 40)
ms=(LG+C60+R LG+C60+R+PMSF)
seq=30
target=root
ts=(time.tre rate.tre)


######################################################
while [ $# -gt 0 ]; do
	case $1 in
		-m)
			OLDIFS=$IFS; IFS=',' read -r -a ms <<< "$2"; IFS=$OLDIFS
			shift
			;;
		--range)
			OLDIFS=$IFS; IFS=',' read -r -a range <<< "$2"; IFS=$OLDIFS
			shift
			;;
		--seq)
			seq=$2
			shift
			;;
		--target|-c)
			target=$2
			shift
			;;
	esac
	shift
done


######################################################
declare -A h; declare -A H
h[time.tre]=figtree.nwk; h[rate.tre]=rate.tre; H[time.tre]=F; H[rate.tre]=T


######################################################
for i in `seq 1 $seq`; do
	echo -e "\n\n$i"
	for j in ${range[@]}; do
		for t in ${ts[@]}; do
			for m in ${ms[@]}; do
				Rscript ~/lab-tools/dating/hessian/calculate_branch_score_dist.R $i/*-$j/$target/dating/$m/combined/${h[$t]} $i/*-$j/$target/sim/tree/$t haha haha ${H[$t]}
			done
		done
		echo
	done
done


