#! /bin/bash


######################################################
dir=`realpath $PWD`


######################################################
outdir=''
is_force=false


######################################################
while [ $# -gt 0 ]; do
	case $1 in
		--outdir)
			outdir=`realpath $2`
			shift
			;;
		--force)
			is_force=true
			;;
	esac
	shift
done

[ $outdir == '' ] && echo "outdir has to be specified!" && exit 1
mkdir -p $outdir


######################################################
for k in `seq 30`; do
	echo $k
	cd $k
		subdir=`realpath $PWD`
		for age in 10 20 30 40; do
			for i in root calib-2_0.2; do
				cd age-$age/$i
				tmp_out=$outdir/tmp.out
				for m in ori LG+G LG+C20+G LG+C40+G; do
					Rscript ~/project/Rhizobiales/scripts/dating/hessian/calculate_branch_score_dist.R sim/tree/time.tre dating/$m/combined/figtree.nwk 1 2 F
				done > $tmp_out
				cut -f1 $tmp_out | transpose.rb -i - >> $outdir/$i-$age.score
				cut -f2 $tmp_out | transpose.rb -i - >> $outdir/$i-$age.reldiff
				cut -f3 $tmp_out | transpose.rb -i - >> $outdir/$i-$age.coefficient
				cut -f4 $tmp_out | transpose.rb -i - >> $outdir/$i-$age.rs
				rm $tmp_out
				cd - >/dev/null
			done
			cd $subdir
		done
		cd $dir
done

 
