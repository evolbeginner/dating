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
for k in `seq 1 30`; do
	echo $k
	cd $k
		subdir=`realpath $PWD`
		for age in 10 20 30 40; do
			for i in root calib-2_0.2; do
				cd age$age/$i
				tmp_out=$outdir/tmp.out
				for m in ori LG+G LG+C20+G LG+C40+G; do
					if [ -f dating/$m/mcmctree/mcmc.txt.gz ]; then
						zcat dating/$m/mcmctree/mcmc.txt.gz | awk '{a+=$(NF-2)}END{print a/NR}'
					else
						awk '{a+=$(NF-2)}END{print a/NR}' dating/$m/mcmctree/mcmc.txt
					fi
				done > $tmp_out
				cut -f1 $tmp_out | transpose.rb -i - >> $outdir/$i-$age.mu
				rm $tmp_out
				cd - >/dev/null
			done
			cd $subdir
		done
		cd $dir
done
  
