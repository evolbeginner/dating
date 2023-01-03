#! /bin/bash


indir=$1


##############################################################
if [ ! -d $indir ]; then
	echo "indir $indir doesn't exist! Exiting ......" >&2
	exit 1
fi


##############################################################
indir=${indir%/}
cp -r $indir $indir.tmp

cd $indir.tmp >/dev/null

sed 's/print.\+/print = -1/' -i mcmctree.ctl

bash ~/project/Rhizobiales/scripts/dating/run_mcmctree_in_batch.sh --indir . --hpc


