#! /usr/bin/env bash


################################################################
indir=''
model=''
length=1000
range=0.2

outdir=''
is_force=false


################################################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		-m)
			model=$2
			shift
			;;
		--length)
			length=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--force)
			is_force=true
			;;
		--range)
			range=$2
			shift
			;;
	esac
	shift
done


################################################################
sub_intree=$indir/sub.tre
time_intree=$indir/time.tre
root_age=`nw_distance $time_intree | tail -1 | cut -f 2`

if [ -f $outdir ]; then
	if [ $is_force == false ]; then
		echo "outdir exists! Exiting ......" >&2
		exit 1
	fi
	rm -rf $outdir
fi
mkdir -p $outdir

species_tree=$outdir/species.trees


################################################################
#echo "iqtree -pre $outdir/iqtree -af fasta -quiet --alisim alignment -m $model -t $sub_intree --length $length"; exit
iqtree -pre $outdir/iqtree -af fasta -quiet --alisim alignment -m $model -t $sub_intree --length $length
MFAtoPHY.pl $indir/alignment.fa; rm $indir/alignment.fa
mv $indir/alignment.fa.phy $outdir/combined.phy #combined.phy to mcmctree.phy

num=`nw_distance -n $time_intree | wc -l | awk '{print $1}'`
echo -e "$num\t1" > $species_tree
nw_topology $time_intree >> $species_tree

#root_max=`echo "scale=2; $root_age * 1.2"|bc`
root_max=`awk '{print $0 * (1+"'$range'")}' <<< $root_age`
#root_min=`echo "scale=2; $root_age * 0.8"|bc`
root_min=`awk '{print $0 * (1-"'$range'")}' <<< $root_age`
root_calib=">$root_min<$root_max"

sed -i 's/;/'$root_calib';/' $species_tree

cd $outdir

