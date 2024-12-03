#! /bin/bash


###############################################################################################
source ~/.bash_profile


###############################################################################################
DIR=`dirname $0`

indir=''
type=''
suffix=''
prefix=mib #mcmctree in batch
w_arg=''


###############################################################################################
cmd="[ -f FigTree.tre ] && rm FigTree.tre; [ -f figtree.nwk ] && rm figtree*.nwk; [ -f rate.tre ] && rm rate.tre;mcmctree > mcmctree.final; bash ~/project/Rhizobiales/scripts/dating/figtree2tree.sh -i FigTree.tre > figtree.nwk; grep rategram out.txt >/dev/null && grep -A1 rategram out.txt | tail -1 > rate.tre"


while [ $# -gt 0 ]; do
	case $1 in
		--indir)
			indir=$2
			shift
			;;
		--nohup)
			type="nohup"
			;;
		--hpc|--HPC)
			type=hpc
			;;
		--wait)
			type=wait
			;;
		--pre|--prefix)
			prefix=$2
			shift
			;;
		-w)
			w_arg="-w $2"
			shift
			;;
		*)
			echo "Wrong argu $1" >&2
			exit 1
	esac
	shift
done


if [ -z $indir ]; then
	echo "indir not given! Exiting ......" >&2
	exit 1
fi


###############################################################################################
for i in `find $indir -name mcmctree.ctl`; do
	d=`dirname $i`
	cd $d;
	d_b=`basename $d`
	[ $d_b == '.' ] && d_b=''
	case $type in
		nohup)
			#mcmctree > mcmctree.final &
			nohup sh -c "$cmd" &
			;;
		hpc)
			submitHPC.sh --cmd "$cmd" -n 1 -l $prefix$d_b.lsf $w_arg
			;;
		wait)
			sh -c "$cmd"
			;;
		*)
			exit 1
			;;
	esac
	cd -
done


