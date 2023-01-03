#! /bin/bash


##############################################
indir=''
is_all=false
run_mode='--hpc'


##############################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--all)
			is_all=true
			;;
		--hpc)
			run_mode='--hpc'
			;;
		--nohup)
			run_mode='--nohup'
			;;
	esac
	shift
done

[ ! -d $indir ] && echo "indir $indir does not exists! Exiting ......" >&2 && exit 1


##############################################
for i in species.trees*; do
	c=${i#species.trees}
	if [ -d $indir/combined$c ]; then
		if [ "$is_all" == false ]; then
			continue
		fi
	else
		for j in $indir/*; do
			cp -r $j $indir/combined$c
			break
		done
	fi

	echo $c
	cp $i $indir/combined$c/species.trees
	
	cd $indir/combined$c/
	bash ~/project/Rhizobiales/scripts/dating/run_mcmctree_in_batch.sh --indir . $run_mode
	cd - >/dev/null
done


