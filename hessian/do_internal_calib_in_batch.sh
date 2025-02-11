#! /bin/bash

DIR=`realpath $PWD`


##############################################
PCD=~/lab-tools/dating/hessian/perform_calib_dating.rb

n=2
cpu=4
p=0.2
s=0
s_name=''
only_min=''
only_max=''


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
		-s|--sp|--shift)
			s=$2
			shift
			;;
		--only_min)
			only_min='--only_min'
			shift
			;;
		--only_max)
			only_max='--only_max'
			shift
			;;
		--cpu)
			cpu=$2
			shift
			;;
	esac
	shift
done


if [ $s != 0 ]; then
	s_name="-s$s"
fi


##############################################
for i in `ls`; do
	[ ! -d $i ] && continue
	[[ ! $i =~ ^[0-9]+$ ]] && continue
	cd $i
	for j in `ls`; do
		cd $j
		pwd
		[ ! -d root ] && echo "wrong directory $i!" && cd $DIR
		outdir=calib-${n}_$p$s_name$only_min$only_max
		rm -rf $outdir
		#echo "ruby ~/project/Rhizobiales/scripts/dating/hessian/perform_calib_dating.rb --indir root/ --outdir $outdir --run_mcmctree --num $n -p $p --force --cpu $cpu"
		ruby $PCD --indir root/ --outdir $outdir --run_mcmctree --num $n -p $p -s $s --force --cpu $cpu $only_min $only_max >/dev/null
		cd - >/dev/null
	done
	cd $DIR
done


