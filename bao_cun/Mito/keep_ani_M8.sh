#! /bin/bash


###########################################################
#TAXA_EXCLUDED="Alexandrium_tamarense Symbiodinium_minutum Paramecium_tetraurelia Oxytricha_trifallax Reticulomyxa_filosa Elphidium_margaritaceum alphaproteobacterium_SCGC_AAA280-P20 alphaproteobacterium_SCGC_AAA288-N07"


###########################################################
is_keep_Pisani=false
is_keep_ani=false


###########################################################
while [ $# -gt 0 ]; do
	case $1 in
		--Pisani|--pisani|-P)
			is_keep_Pisani=true
			;;
		--ani|-a)
			is_keep_ani=true
			;;
	esac
	shift
done


###########################################################
if [ $is_keep_ani == false ]; then
	rm pep-sing/mito-MitoCOG0133.fas
	rm pep-sing/mito-MitoCOG00{2,3,4,5,6,7,8,9}*
fi

if [ $is_keep_Pisani == false ]; then
	rm pep-sing/Pisani*
fi


###########################################################
mkdir date-sing; bash ~/LHW-tools/SEQ2TREE/SEQ2TREE.sh --seq_indir pep-sing/ --outdir tree-sing/ --force --cpu 10 --iqtree --model3 --add_gaps; cd date-sing; ruby ~/project/Rhizobiales/scripts/dating/createSeqfile4Mcmctree.rb --indir ../tree-sing/gap_aln --outdir phylip --force --min 1; cat phylip/* > combined.phy;


###########################################################
if [ $is_keep_Pisani == false ]; then
	for i in ./species.trees*; do
		echo $i
		b=`basename $i`
		new_tree=$b
		#sed '1d' $i | nw_prune - $TAXA_EXCLUDED | sponge $new_tree
		#no_of_species=`nw_stats $new_tree | grep 'leaves'|cut -f 2`
		#echo -e "$no_of_species\t1" | cat - $new_tree | sponge $new_tree
	done
fi


