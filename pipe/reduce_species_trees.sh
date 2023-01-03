#! /bin/bash


#####################################
DIR=`realpath \`dirname $0\``


#####################################
while [ $# -gt 0 ]; do
	case $1 in
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


#####################################
if [ -d $outdir ]; then
	if [ $is_force == true ]; then
		rm -rf $outdir
	else
		echo "outdir $outdir has existed! Exiting ......" >&2
		exit 1
	fi
fi

mkdir -p $outdir


#####################################
if [ ! -z $outdir ]; then
	perl $DIR/../calib/change_species_tree_skew_calib.pl --tree $species_trees --convert 1 | nw_prune -vf - $species_list > $outdir/species.trees
	numTaxa=`nw_stats $outdir/species.trees | grep 'leaves' | awk '{print $2}'`
	perl $DIR/../calib/change_species_tree_skew_calib.pl --tree $outdir/species.trees --convert 2 | sponge $outdir/species.trees
	echo -e "$numTaxa\t1" | cat - $outdir/species.trees | sponge $outdir/species.trees
fi


