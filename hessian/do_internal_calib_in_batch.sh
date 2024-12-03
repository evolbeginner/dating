#! /bin/bash

DIR=`realpath $PWD`


##############################################
n=2
cpu=4
p=0.2


##############################################
while [ $# -gt 0 ]; do
	case $1 in
		-n)
			n=$2
			shift
			;;
		-p)
			p=$2
			shift
			;;
		--cpu)
			cpu=$2
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
		rm -rf $outdir
		#bash ~/project/Rhizobiales/scripts/dating/hessian/perform_calib_dating.sh --indir root/ --outdir $outdir --run_mcmctree --num $n --force
		#echo "ruby ~/project/Rhizobiales/scripts/dating/hessian/perform_calib_dating.rb --indir root/ --outdir $outdir --run_mcmctree --num $n -p $p --force --cpu $cpu"
		ruby ~/project/Rhizobiales/scripts/dating/hessian/perform_calib_dating.rb --indir root/ --outdir $outdir --run_mcmctree --num $n -p $p --force --cpu $cpu
		cd - >/dev/null
	done
	cd $DIR
done


