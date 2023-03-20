#! /bin/bash


#############################################
source ~/tools/self_bao_cun/packages/bash/util.sh


#############################################
indir=''
outdir=''
is_force=false


#############################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--force)
			is_force=true
			;;
	esac
	shift
done


#############################################
mkdir_with_force $outdir $is_force

[ $? != 0 ] && exit


#############################################
for i in mcmctree.ctl species.trees combined.phy; do
	cp $indir/$i $outdir/
done

ln -s `realpath $indir/mcmc.txt` $outdir
cd $outdir

sed -i 's/print.\+/print = -1/' mcmctree.ctl
bash ~/project/Rhizobiales/scripts/dating/run_mcmctree_in_batch.sh --indir . --nohup


