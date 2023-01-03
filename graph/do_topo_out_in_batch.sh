#! /bin/bash


#############################################################
source ~/tools/self_bao_cun/packages/bash/util.sh


#############################################################
SUBTREE_INDIR=~/project/BTL/results/dating/official/wCelegans-correct/subtrees/
FIGTREE2TREE=~/project/Rhizobiales/scripts/dating/figtree2tree.sh
READ_FIGTREE=~/project/Rhizobiales/scripts/dating/readFigtree.rb
GENERATE_TOPO_HPD=~/project/Rhizobiales/scripts/dating/graph/generate_topo_hpd_interval.rb


#############################################################
function create_tmp_figtree(){
	[ ! -d $1/tmp ] && mkdir $1/tmp
	cd $1/tmp
	[ ! -d $1/tmp ] && ln -s ../{mcmc.txt,species.trees,combined.phy} ./
	cp ../mcmctree.ctl ./
	sed -i 's/print.\+/print = -1/' mcmctree.ctl
	mcmctree > mcmctree.final; bash $FIGTREE2TREE -i FigTree.tre > figtree.nwk	
	cd -
}


#############################################################
indirs=()
c=''
minmax=0,4500
is_force=false


#############################################################
args=$@

while [ $# -gt 0 ]; do
	case $1 in
		--indir|-i)
			indirs=(${indirs[@]} $2)
			shift
			;;
		--minmax|--min_max)
			minmax=$2
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--force)
			is_force=true
			;;
		*)
			echo "Unknown param $1! Exiting ......" >&2
			exit 1
	esac
	shift
done


mkdir_with_force $outdir $is_force
[ $? != 0 ] && echo "outdir wrong! Exiting ......" && exit 1

topo_out=$outdir/topo.out
topo_list=$outdir/topo.list
graph_file=$outdir/grperr.pdf

echo "$args" > $outdir/args


#############################################################
for i in ${indirs[@]}; do
	echo `basename $i`;

	[ ! -d $i ] && echo "The indir $i does not exist! Exiting ......" >&2 && exit 1

	if [ ! -f "$i/FigTree.tre" ]; then
		create_tmp_figtree $i >/dev/null
		indir=$i/tmp
	else
		indir=$i
	fi

	for j in $SUBTREE_INDIR/*; do
		b=`basename $j`
		a=`ruby $READ_FIGTREE --species_tree $indir/FigTree.tre -t $j --tmpfile | awk -F" " 'BEGIN{OFS="\t"}{print $1*100,$2*100,$3*100}'`
		[ ! -z "$a" ] && echo -e "$b\t$a"
	done
	echo
done | tee $topo_out

ruby $GENERATE_TOPO_HPD -i $topo_out > $topo_list

Rscript ~/project/Rhizobiales/scripts/dating/graph/grp_err_graph.R -i $topo_list -m $minmax -o $graph_file


