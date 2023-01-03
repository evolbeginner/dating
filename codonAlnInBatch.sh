#! /bin/bash


######################################################################
PAL2NAL=pal2nal.pl

codon_table=1
is_force=0


######################################################################
while [ $# -gt 0 ]; do
	case $1 in
		--cds|--cds_indir)
			cds_indir=$2
			shift
			;;
		--prot|--pep|--prot_indir|--pep_indir)
			prot_indir=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--codon_table)
			codon_table=$2
			shift
			;;
		--force)
			is_force=1
			;;
	esac
	shift
done


######################################################################
if [ -z $outdir ]; then
	echo "outdir must be given! Exiting ......" >&2
	exit 1
fi

if [ -d $outdir ]; then
	if [ $is_force == 1 ]; then
		rm -rf $outdir 
	else
		echo "outdir $outdir already exists. Exiting ......" >&2
		exit 1
	fi
fi

mkdir -p $outdir


######################################################################
for i in $prot_indir/*; do
	b=`basename $i`
	c=${b%%.*}
	[ ! -f $cds_indir/$c* ] && continue
	$PAL2NAL $i $cds_indir/$c* -output fasta -codontable $codon_table > $outdir/$c.aln
done


