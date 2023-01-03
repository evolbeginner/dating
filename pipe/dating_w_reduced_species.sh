#! /bin/bash


#########################################################
DIR=`realpath \`dirname $0\``


#########################################################
indir=''
species_list=''
species_trees=''
is_force=false


#########################################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--species_list)
			species_list=$2
			shift
			;;
		--species_trees)
			species_trees=$2
			shift
			;;
		--species_trees_dir)
			species_trees_dir=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--force)
			is_force=true
			;;
		*)
			echo "wrong param $2" >&2
			exit 1
			;;
	esac
	shift
done


if [ -z $outdir ]; then
	echo "outdir has to be given! Exiting ......" >&2
	exit 1
fi


#########################################################
if [ -d $outdir ]; then
	if [ $is_force == true ]; then
		rm -rf $outdir
	else
		echo "outdir $outdir has existed! Exiting ......" >&2
		exit 1
	fi
fi
mkdir -p $outdir


#########################################################
bash ~/tools/self_bao_cun/basic_process_mini/filterSeqInBatch.sh --indir $indir --include_list $species_list --outdir pep

bash ~/LHW-tools/SEQ2TREE/SEQ2TREE.sh --seq_indir pep --outdir tree.sp --cpu 12 --add_gaps --lg --force --iqtree

#sed '1d' $species_trees | sed 's/"(\([^"]\+)\)"/\1/' | nw_prune -vf - $species_list > $outdir/species.trees
if [ ! -z "$species_trees" ]; then
	perl $DIR/../calib/change_species_tree_skew_calib.pl --tree $species_trees --convert 1 | nw_prune -vf - $species_list > $outdir/species.trees
	numTaxa=`nw_stats $outdir/species.trees | grep 'leaves' | awk '{print $2}'`
	perl $DIR/../calib/change_species_tree_skew_calib.pl --tree $outdir/species.trees --convert 2 | sponge $outdir/species.trees
	echo -e "$numTaxa\t1" | cat - $outdir/species.trees | sponge $outdir/species.trees
else
	for species_trees in $species_trees_dir/species.trees*; do
		b=`basename $species_trees`
		echo $species_trees
		perl $DIR/../calib/change_species_tree_skew_calib.pl --tree $species_trees --convert 1 | nw_prune -vf - $species_list > $outdir/$b
		numTaxa=`nw_stats $outdir/$b | grep 'leaves' | awk '{print $2}'`
		perl $DIR/../calib/change_species_tree_skew_calib.pl --tree $outdir/$b --convert 2 | sponge $outdir/$b
		echo -e "$numTaxa\t1" | cat - $outdir/$b | sponge $outdir/$b
	done
fi

cp tree.sp/combined.phy $outdir/combined.phy


