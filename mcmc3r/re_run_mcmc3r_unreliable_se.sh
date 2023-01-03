#! /bin/env bash


################################################
PROG=~/project/Rhizobiales/scripts/dating/mcmc3r/calculate_mcmc3r_logml.R


################################################
times=2


################################################
while [ $# -gt 0 ]; do
	case $1 in
		--times)
			times=$2
			shift
			;;
	esac
	shift
done


################################################
#read beta
count=0
declare -A beta

if [ ! -f beta.txt ]; then
	echo "no file beta.txt found!" >&2
	exit 1
fi

while read line; do
	count=$((++count))
	#beta[$count]=$line
	beta["$line"]=$count
done < beta.txt


################################################
for i in `Rscript $PROG 2>&1 | grep "unreliable se" | awk '{print $NF}'`; do
	#if [[ ${beta[@]} =~ $i ]]; then
	if [ "${beta[$i]+abc}" ]; then
		dir=${beta[$i]}
		echo $dir
		awk -v times=$times '{if(/nsample =/){print "nsample =", $3*times} else{print}}' $dir/mcmctree.ctl | sponge $dir/mcmctree.ctl
		cd $dir >/dev/null 2>&1
		bash ~/project/Rhizobiales/scripts/dating/run_mcmctree_in_batch.sh --indir . --hpc
		cd - >/dev/null 2>&1
	fi
done


