#! /bin/bash


##########################################
infiles=()


##########################################
while [ $# -gt 0 ]; do
	case $1 in
		-i)
			infiles=(${infiles[@]} $2)
			shift
			;;
		--indir)
			indir=$2
			shift
			;;
		--ref_dir)
			ref_dir=$2
			shift
			;;
		*)
			echo "Unknown param!" >&2
			exit 1
	esac
	shift
done


##########################################
if [ ${#infiles[@]} == 0 ]; then
	for i in $indir/species.trees*; do
		infiles=(${infiles[@]} $i)
	done
fi


##########################################
outdir0=`dirname $ref_dir`

for infile in ${infiles[@]}; do
	b=`basename $infile`
	outdir_suffix=${b#species.trees}
	outdir=$outdir0/combined$outdir_suffix
	if [ ! -d $outdir ]; then
		cp -r $ref_dir $outdir
		cp $infile $outdir/species.trees
		echo $b
		cd $outdir >/dev/null
		bash ~/project/Rhizobiales/scripts/dating/run_mcmctree_in_batch.sh --indir . --hpc
		cd - >/dev/null
	fi
done


