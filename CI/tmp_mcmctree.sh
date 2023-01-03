#! /bin/bash


##########################################################
is_figtree=false
is_CI=false


##########################################################
while [ $# -gt 0 ]; do
	case $1 in
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
if [ $is_figtree ]; then
	sed 's/print.\+=/print = -1/' -i mcmctree.ctl
	mcmctree > mcmctree.final
fi


##########################################################
if [ $is_CI == true ]; then
	~/project/Rhizobiales/scripts/dating/CI/get_bl_CI_interval.sh FigTree.tre  --multiply 100 --format mcmctree  --ci --header > date.tbl
	Rscript ~/project/Rhizobiales/scripts/dating/graph/generate_infinite_plot.R -i date.tbl -o b.pdf -m 0,4500
fi


