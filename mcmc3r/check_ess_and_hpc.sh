#! /bin/bash


#####################################################
A=$PWD;


#####################################################
is_hpc=false
is_nohup=false
types=()
is_only_echo=false


#####################################################
while [ $# -gt 0 ]; do
	case $1 in
		--hpc)
			is_hpc=true
			;;
		--nohup)
			is_nohup=true
			;;
		--type)
			types=(${types[@]} $2)
			shift
			;;
		--only_echo)
			is_only_echo=true
			;;
		*)
			echo "Wrong argu $1; Exiting ......" >&2
			exit 1
	esac
	shift
done


#####################################################
for t in ${types[@]}; do
	cd $t

	for j in `seq 1 1 8`; do
		d=`pwd`
		a=`Rscript ~/project/Rhizobiales/scripts/dating/ESS/calculate_ess.R $j/mcmc.txt | tail -1`
		b=`awk -v n1=$a -v n2=100 'BEGIN{if(n1<n2){print 0}else{print 1}}'`
		if [ $b == 0 ]; then
			echo -e "$d\t$j"
			if [ $is_only_echo == true ]; then
				echo -e "$d\t$j"
			else
				sed -i 's/burnin = .\+/burnin = 100000/; s/sampfreq = .\+/sampfreq = 10/; s/nsample = .\+/nsample = 100000/' $j/mcmctree.ctl
			fi

			cd $j
			if [ $is_hpc == true ]; then
				submitHPC.sh --cmd 'mcmctree > mcmctree.final' -n 1 -l $j.lsf --df
			elif [ $is_nohup == true ]; then
				nohup mcmctree > mcmctree.final &
			fi
			cd ..
		fi
	done
	cd $A #return

done

