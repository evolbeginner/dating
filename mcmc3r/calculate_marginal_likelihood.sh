#! /bin/bash


##########################################
wd=`pwd`


##########################################
for i in `ls`; do
	[ ! -d "$i" ] && continue
	cd $i/date/mcmc3r
	logmls=(); ses=()
	echo -ne "$i\t"
	for t in AR IR; do
		cd $t
		#cmd="Rscript ~/project/Rhizobiales/scripts/dating/mcmc3r/calculate_mcmc3r_logml.R 2>/dev/null"
		logml=`Rscript ~/project/Rhizobiales/scripts/dating/mcmc3r/calculate_mcmc3r_logml.R 2>/dev/null | awk '{print $1}'`
		logmls=(${logmls[@]} $logml)
		se=`Rscript ~/project/Rhizobiales/scripts/dating/mcmc3r/calculate_mcmc3r_logml.R 2>/dev/null | awk '{print $2}'`
		ses=(${ses[@]} $se)
		cd - >/dev/null
	done
	logml_diff=`echo -e "scale=3; ${logmls[0]} - ${logmls[1]}" | bc`
	ratio=`echo -e "e($logml_diff)" | bc -l`
	marginal_lh=`echo -e "scale=3; $ratio/($ratio+1)" | bc` # AR
	echo -ne "$logml_diff\t$marginal_lh\t"
	echo -ne "${logmls[@]}\t" | tr ' ' '\t'
	echo "${ses[@]}" | tr ' ' '\t'
	cd $wd >/dev/null
done


