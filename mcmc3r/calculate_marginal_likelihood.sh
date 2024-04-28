#! /bin/bash


##########################################
wd=`pwd`


##########################################
for i in `ls`; do
	[ ! -d "$i" ] && continue
	cd $i/date/mcmc3r
	logmls=()
	for t in AR IR; do
		cd $t
		logml=`Rscript ~/project/Rhizobiales/scripts/dating/mcmc3r/calculate_mcmc3r_logml.R 2>/dev/null`
		logmls=(${logmls[@]} $logml)
		cd - >/dev/null
	done
	logml_diff=`echo -e "scale=3; ${logmls[0]} - ${logmls[1]}" | bc`
	ratio=`echo -e "e($logml_diff)" | bc -l`
	marginal_lh=`echo -e "scale=3; $ratio/($ratio+1)" | bc` # AR
	echo -e "$logml_diff\t$marginal_lh"
	cd $wd >/dev/null
done


