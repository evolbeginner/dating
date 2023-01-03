#! /bin/bash


##############################################
source ~/tools/self_bao_cun/packages/bash/util.sh


##############################################
MAKE_CALIB_TO_TREE=~/project/Rhizobiales/scripts/dating/hessian/make_calib_to_tree.R

indir=''
outdir=''
only_min_arg=''
is_force=false
is_run_mcmctree=false
num=2


##############################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--num)
			num=$2
			shift
			;;
		--only_min)
			only_min_arg='--only_min'
			;;
		--run_mcmctree)
			is_run_mcmctree=true
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--force)
			is_force=true
			;;
		*)
			echo "wrong param $2! Exiting ......"
			exit 1
			;;
	esac
	shift
done


##############################################
mkdir_with_force $outdir $is_force

cp -r $indir/sim $outdir
cp -r $indir/dating $outdir

DIR=`realpath $PWD`


##############################################
timetree=$indir/sim/tree/time.tre
tipN=`nw_stats $timetree | grep leaves | awk '{print $2}'`
new_tree=`$MAKE_CALIB_TO_TREE -t $timetree -n $num $only_min_arg | nw_topology -`

for i in `find $outdir -name 'species.trees'`; do
	echo $i
	d=`dirname $i`
	cd $d
	echo -e "$tipN\t1\n$new_tree" > species.trees
	[ "$is_run_mcmctree" == true ] && bash ~/project/Rhizobiales/scripts/dating/run_mcmctree_in_batch.sh --indir . --hpc
	cd - >/dev/null
done


