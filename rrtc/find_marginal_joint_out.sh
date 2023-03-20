#! /bin/bash


#####################################################
source ~/.bash_profile


#####################################################
OBS_PATH=`realpath \`readlink -f $0\``
DIR=`dirname $OBS_PATH`

name=''
outdir=''
is_force=false
is_bb=true
greps=()
grepvs=()

arg=$@


#####################################################
copy_bb(){
	SAMPLEDIR=$DIR/sample_find_mj_out
	if [ $is_bb == true ]; then
		cp $SAMPLEDIR/$t/{Blattabacterium,Buchnera}.tbl $outdir/$t
	fi
}


#####################################################
while [ $# -gt 0 ]; do
	case $1 in
		--name)
			name=$2
			shift
			;;
		--grep)
			greps=(${greps[@]} $2)
			shift
			;;
		--grepv)
			grepvs=(${grepvs[@]} $2)
			shift
			;;
		--outdir)
			outdir=$2
			shift
			;;
		--force)
			is_force=true
			;;
		--nobb|--no_bb)
			is_bb=false
			;;
		*)
			echo "unknown param $1" >&2
			exit 1
			;;
	esac
	shift
done


#####################################################
if [ "$name" == '' ]; then
	echo "name must be given by --name"
	exit 1
elif [ "$outdir" == '' ]; then
	echo "outdir must be given by --outdir"
	exit 1
fi

mkdir_with_force $outdir $is_force
if [ $? -ne 0 ]; then
	echo "outdir wrong! Exiting ....."; exit 1
fi

args_outfile=$outdir/args
echo -e "$arg\n" > $args_outfile


#####################################################
for t in marginal joint; do
	a=`find ~/project/PTL/results/host_asr/ -mindepth 9 -name $t.scm_out`

	echo $t >> $args_outfile
	for i in ${a[@]}; do
		is_continue=false
		if [ ! -z $greps ]; then
			for grep in ${greps[@]}; do
				if ! grep "$grep" <<< $i >/dev/null; then is_continue=true; fi
			done
		fi
		if [ ! -z $grepvs ]; then
			for grepv in ${grepvs[@]}; do
				if grep "$grepv" >/dev/null <<< $i; then is_continue=true; fi
			done
		fi

		[ $is_continue == true ] && continue
		echo $i

		mkdir -p $outdir/$t
		d=`basename \`dirname $i\``
		[ $d != $name ] && continue
		taxon=${i#*host_asr/}
		taxon=${taxon%%/*}
		#echo $taxon >&2
		cat $i > $outdir/$t/$taxon.tbl
		echo $i >> $args_outfile
	done
	echo >> $args_outfile

	copy_bb $t

	if [ $t == marginal ]; then
		for i in $outdir/$t/*; do
			cat $i
			echo
		done > $outdir/$t.tbl
	fi
	echo
done


