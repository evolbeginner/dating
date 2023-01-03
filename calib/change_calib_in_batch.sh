#! /bin/bash


#########################################################
DIR=`dirname $0`
CHANGE_CALIB=$DIR/change_calib.rb


#########################################################
indir=''
template_dir=''
species_trees=''
outdir=''
is_force=false
is_soft=false
clock=''


#########################################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--template_dir)
			template_dir=$2
			shift
			;;
		--species_trees)
			species_trees=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--force)
			is_force=true
			;;
		--soft)
			is_soft=true
			;;
		--hard)
			is_soft=false
			;;
		--clock)
			clock=$2
			shift
			;;
	esac
	shift
done


#########################################################
if [ -d $outdir ]; then
	if [ $is_force == true ]; then
		rm -rf $outdir
	else
		echo "outdir $outdir already exists! Exiting ......"
		exit 1
	fi
fi

mkdir -p $outdir


#########################################################
for i in $indir/*; do
	b=`basename $i`
	sub_outdir=$outdir/$b
	cp -r $template_dir $sub_outdir
	head -1 $template_dir/species.trees > $sub_outdir/species.trees

	if [ -f "$species_trees" ]; then
		species_trees=$species_trees
	else
		species_trees=$template_dir/species.trees
	fi
	intree=`perl ~/project/Rhizobiales/scripts/dating/calib/change_species_tree_skew_calib.pl --tree $species_trees --convert 1 | nw_topology -I -`

	if [ $is_soft == true ]; then
		echo $intree | ruby $CHANGE_CALIB -i - --calib $i --del_all >> $sub_outdir/species.trees
	else
		echo $intree | ruby $CHANGE_CALIB -i - --calib $i --del_all --unif 0,0.025 >> $sub_outdir/species.trees
	fi

	# set the clock model
	if [ "$clock" != '' ]; then
		case $clock in
			IR)
				sed -i 's/clock.\+/clock = 2/' $sub_outdir/mcmctree.ctl
				;;
			AR)
				sed -i 's/clock.\+/clock = 3/' $sub_outdir/mcmctree.ctl
				;;
		esac
	fi

	[ -f $sub_outdir/FigTree.tre ] && rm $sub_outdir/FigTree.tre
done


