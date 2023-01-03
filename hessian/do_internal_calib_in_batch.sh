#! /bin/bash

DIR=`realpath $PWD`


##############################################
n=2
p=0.2


##############################################
while [ $# -gt 0 ]; do
	case $1 in
		-n)
			n=$2
			shift
			;;
	esac
	shift
done


##############################################
for i in `ls`; do
	[ ! -d $i ] && continue
	cd $i
	for j in `ls`; do
		cd $j
		pwd
		[ ! -d root ] && echo "wrong directory $i!" && cd $DIR
		outdir=calib-${n}_$p
		bash ~/project/Rhizobiales/scripts/dating/hessian/perform_calib_dating.sh --indir root/ --outdir $outdir --run_mcmctree --num $n
		cd - >/dev/null
	done
	cd $DIR
done


