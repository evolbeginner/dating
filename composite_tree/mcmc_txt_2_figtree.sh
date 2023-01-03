#! /usr/bash


#############################################################
DIR=`dirname $0`
#ruby ~/project/Rhizobiales/scripts/dating/parse_tree_mcmctree.rb -i ../../IR/mcmctree.final --output_node_taxon > node2taxon.tbl


#############################################################
READ_MCMC_TXT=$DIR/read_mcmc_txt.rb 
OUTPUT_HPD=$DIR/output_hpd.R
CALCULATE_OVERLAP=~/tools/self_bao_cun/others/calculate_overlaps.rb
MAP=$DIR/map_age_2_figtree.rb
PARSE_TREE_MCMCTREE=$DIR/parse_tree_mcmctree.rb
TMPDIR=/tmp/123


#############################################################
infiles=()
cpu=1
outdir=''
is_force=false


#############################################################
while [ $# -gt 0 ]; do
	case $1 in
		-i)
			infiles=(${infiles[@]} $2)
			shift
			;;
		-t)
			treefile=$2
			shift
			;;
		--species_trees)
			species_trees_file=$2
			mkdir -p $TMPDIR;
			treefile=$TMPDIR/species.nwk
			sed '1d' $species_trees_file > $treefile
			shift
			;;
		--cpu)
			cpu=$2
			shift
			;;
		--node2taxon)
			node2taxon_file=$2
			shift
			;;
		--mcmctree_final)
			mcmctree_final_file=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--force)
			is_force=true
			;;
	esac
	shift
done


#############################################################
if [ -d $outdir ]; then
	if [ $is_force == true ]; then
		rm -rf $outdir
	else
		echo "outdir $outdir has existed! Exiting ......" 2>/dev/null; exit 1
	fi
fi
mkdir $outdir


#############################################################
for infile in ${infiles[@]}; do
	infile_args=(${infile_args[@]} "-i $infile")
done

ruby $READ_MCMC_TXT ${infile_args[@]} -n $cpu > $outdir/merged_mcmc.txt

#echo "Rscript $OUTPUT_HPD $outdir/merged_mcmc.txt 2>/dev/null > $outdir/age.list"
Rscript $OUTPUT_HPD $outdir/merged_mcmc.txt 2>/dev/null > $outdir/age.list

#echo "ruby $PARSE_TREE_MCMCTREE -i $mcmctree_final_file --output_node_taxon > $outdir/node2taxon.tbl"
ruby $PARSE_TREE_MCMCTREE -i $mcmctree_final_file --output_node_taxon > $outdir/node2taxon.tbl

ruby $CALCULATE_OVERLAP --i1 $outdir/node2taxon.tbl --i2 $outdir/age.list --show 12 --content 1,2 --out_sep $'\t' | cut -f 2,4,5,6 > $outdir/node2age.tbl

#echo "ruby $MAP -i $treefile --age $outdir/node2age.tbl > $outdir/FigTree.tre"
ruby $MAP -i $treefile --age $outdir/node2age.tbl > $outdir/FigTree.tre


