#! /bin/bash


############################################################
DIR=`dirname \`realpath $0\``

indir=''
outdir=''
is_IR=true
is_AR=true
is_SR=true
bsn=10000,10,1000


############################################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;		
		--no_SR|--noSR)
			is_SR=false
			;;
		--no_AR|--noAR)
			is_AR=false
			;;
		--no_IR|--noIR)
			is_IR=false
			;;
		--bsn)
			bsn=$2
			shift
			;;
		*)
			echo "unknown param $1!"
			exit 1
			;;
	esac
	shift
done


############################################################
OLDIFS=$IFS
IFS=,
read -r -a bsns <<< "$bsn"
IFS=$OLDIFS
burnin=${bsns[0]}
sampfreq=${bsns[1]}
nsample=${bsns[2]}


############################################################
[ -z $indir ] && echo "indir not given" && exit 1
[ -z $outdir ] && echo "outdir not given" && exit 1


############################################################
mkdir $outdir/{S,A,I}R/{1,2,3,4,5,6,7,8} -p

cp $indir/mcmctree/combined/mcmctree.ctl $indir/combined.phy $indir/species.trees $outdir/SR
cp $indir/mcmctree/combined/mcmctree.ctl $indir/combined.phy $indir/species.trees $outdir/IR
cp $indir/mcmctree/combined/mcmctree.ctl $indir/combined.phy $indir/species.trees $outdir/AR

cd $outdir


############################################################
for i in `find -name mcmctree.ctl`; do sed 's/burnin = .\+/burnin = '"$burnin"'/; s/sampfreq = .\+/sampfreq = '"$sampfreq"'/; s/nsample = .\+/nsample = '"$nsample"'/' -i $i; done

find -name mcmctree.ctl -exec sed 's/usedata = .\+/usedata = 1/' -i {} \;
find -name mcmctree.ctl -exec sed 's/seqtype = .\+/seqtype = 0/' -i {} \;


############################################################
if [ $is_SR == true ]; then
	cd SR
	find -name mcmctree.ctl -exec sed 's/clock = .\+/clock = 1/' -i {} \;
	for i in `seq 1 1 8`; do cp mcmctree.ctl species.trees combined.phy $i; done
	mv mcmctree.ctl mcmctree.ctl0
	Rscript $DIR/mcmc3r.R
	cd ..
fi


if [ $is_IR == true ]; then
	cd IR
	find -name mcmctree.ctl -exec sed 's/clock = .\+/clock = 2/' -i {} \;
	for i in `seq 1 1 8`; do cp mcmctree.ctl species.trees combined.phy $i; done
	mv mcmctree.ctl mcmctree.ctl0
	Rscript $DIR/mcmc3r.R
	cd ..
fi

if [ $is_AR == true ]; then
	cd AR
	find -name mcmctree.ctl -exec sed 's/clock = .\+/clock = 3/' -i {} \;
	for i in `seq 1 1 8`; do cp mcmctree.ctl species.trees combined.phy $i; done
	mv mcmctree.ctl mcmctree.ctl0
	Rscript $DIR/mcmc3r.R
	cd ..
fi


