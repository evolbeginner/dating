#! /bin/bash


####################################################
for i in `ls`; do
	[ ! -d $i ] && continue
	cd $i
	bash ~/project/Rhizobiales/scripts/dating/mcmc3r/mcmc3r.sh --indir . --outdir mcmc3r/
	cd ../
done
