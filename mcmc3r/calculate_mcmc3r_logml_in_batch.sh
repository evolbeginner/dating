#! /bin/bash


#########################################################
A=`pwd`

for i in `ls`; do
	[ ! -d $i ] && continue
	echo -ne "$i\t"
	cd $i/date/mcmc3r/
	cd AR
	ll1=`Rscript ~/project/Rhizobiales/scripts/dating/mcmc3r/calculate_mcmc3r_logml.R`
	cd ../IR
	ll2=`Rscript ~/project/Rhizobiales/scripts/dating/mcmc3r/calculate_mcmc3r_logml.R`
	echo -e "$ll1\t$ll2"
	if [ -d ../SR ] ; then
		cd ../SR
		Rscript ~/project/Rhizobiales/scripts/dating/mcmc3r/calculate_mcmc3r_logml.R
	fi
	cd $A
done 2>/dev/null


