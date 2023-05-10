#! /bin/bash


##########################################################
# a similar one is /home-user/sswang/project/Rhizobiales/scripts/dating/mini/run_tmp_mcmctree.sh


##########################################################
indir=''
is_figtree=false
is_CI=false


##########################################################
while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--figtree)
			is_figtree=true
			;;
		--CI)
			is_CI=true
			;;
	esac
	shift
done


##########################################################
outdir=$indir/tmp

mkdir $outdir

cp $indir/{mcmc.txt,species.trees,mcmctree.ctl,in.BV,combined.phy} $outdir/

cd $outdir >/dev/null


##########################################################
if [ "$is_figtree" == true ]; then
	sed 's/print.\+=/print = -1/' -i mcmctree.ctl
	[ -f FigTree.tre ] && rm FigTree.tre; [ -f figtree.nwk ] && rm figtree*.nwk; mcmctree > mcmctree.final; bash ~/project/Rhizobiales/scripts/dating/figtree2tree.sh -i FigTree.tre > figtree.nwk
fi


##########################################################
if [ "$is_CI" == true ]; then
	~/project/Rhizobiales/scripts/dating/CI/get_bl_CI_interval.sh FigTree.tre  --multiply 100 --format mcmctree  --ci --header > date.tbl
	Rscript ~/project/Rhizobiales/scripts/dating/graph/generate_infinite_plot.R -i date.tbl -o b.pdf -m 0,4500
fi


