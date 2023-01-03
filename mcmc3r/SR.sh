#! /bin/bash


###########################################################
dir=~/project/Rhizobiales/scripts/dating/mcmc3r/
indir=$1


###########################################################
if [ -z $indir ]; then
	echo "indir has to be given! Exiting ......" 2>/dev/null
	exit 1
fi


###########################################################
if [ ! -d SR ]; then mkdir SR; fi

cp $indir/mcmctree/combined/mcmctree.ctl $indir/combined.phy $indir/species.trees SR

cd SR

for i in `find -name mcmctree.ctl`; do sed 's/burnin = .\+/burnin = 10000/; s/sampfreq = .\+/sampfreq = 10/; s/nsample = .\+/nsample = 1000/' -i $i; done

find -name mcmctree.ctl -exec sed 's/usedata = .\+/usedata = 1/' -i {} \;
find -name mcmctree.ctl -exec sed 's/clock = .\+/clock = 1/' -i {} \;

for i in `seq 1 1 8`; do mkdir $i; cp mcmctree.ctl species.trees combined.phy $i; done
mv mcmctree.ctl mcmctree.ctl0
Rscript $dir/mcmc3r.R
cd ..
