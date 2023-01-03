#! /bin/bash


###########################################################
filterSeqInBatch=~/tools/self_bao_cun/basic_process_mini/filterSeqInBatch.sh

indir=''
outdir=''
is_force=false
include_list=''

PWD1=`pwd`


###########################################################
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
		--include_list)
			include_list=$2
			shift
			;;
		--root_gamma)
			root_gamma=$2
			shift
			;;
	esac
	shift
done


###########################################################
if [ -d $outdir ]; then
	if [ $is_force == true ]; then
		rm -rf $outdir
	fi
fi
mkdir -p $outdir


###########################################################
pep_indir=$indir/pep-sing
pep_outdir=$outdir/pep-sing
bash $filterSeqInBatch --indir $pep_indir --include_list $include_list --outdir $pep_outdir

date_indir=$indir/date-sing
date_outdir=$outdir/date-sing
mkdir $date_outdir

cd $outdir
bash ~/LHW-tools/SEQ2TREE/SEQ2TREE.sh --seq_indir pep-sing/ --outdir tree-sing/ --force --cpu 10 --iqtree --model3 --add_gaps --sp; cd date-sing; ruby ~/project/Rhizobiales/scripts/dating/createSeqfile4Mcmctree.rb --indir ../tree-sing/gap_aln --outdir phylip --min 1 --force; cat phylip/* > combined.phy;
cd $PWD1


for i in $date_indir/species.trees*; do
	echo $i
	b=`basename $i`
	new_tree=$date_outdir/$b
	#echo "sed '1d' $i | nw_prune -v - -f $include_list > $new_tree"; exit
	sed '1d' $i | nw_prune -v - -f $include_list > $new_tree
	no_of_species=`nw_stats $new_tree | grep 'leaves'|cut -f 2`
	echo -e "$no_of_species\t1" | cat - $new_tree | sponge $new_tree
	if [ -z $root_gamma ]; then
		sed -i 's/);/)<30;/' $new_tree
	else
		sed -i "s/)[^)]*;/)$root_gamma;/" $new_tree
		#sed -i "s/)[^)]\+;/)$root_gamma;/" $new_tree
	fi
done


