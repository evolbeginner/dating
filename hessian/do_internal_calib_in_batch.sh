#! /bin/bash

DIR=`realpath $PWD`


##############################################
PCD=~/lab-tools/dating/hessian/perform_calib_dating.rb

n=2
cpu=4
p=0.2
s=0
ancient=''
s_name=''
only_min=''
only_max=''


##############################################
while [ $# -gt 0 ]; do
	case $1 in
		-n)
			n=$2
			shift
			;;
		-p)
			p=$2
			shift
			;;
		-s|--sp|--shift)
			s=$2
			shift
			;;
		--only_min)
			only_min='--only_min'
			;;
		--only_max)
			only_max='--only_max'
			;;
		--ancient)
			ancient='--ancient'
			;;
		--cpu)
			cpu=$2
			shift
			;;
	esac
	shift
done


if [ $s != 0 ]; then
	s_name="-s$s"
fi


##############################################
##############################################
# how many folders to process in parallel
jobs=$cpu
running=0

for i in "$DIR"/*; do
	[ ! -d "$i" ] && continue
	i_base=$(basename "$i")
	[[ ! "$i_base" =~ ^[0-9]+$ ]] && continue

	(
		cd "$i" || exit 1
		for j in *; do
			[ ! -d "$j" ] && continue
			cd "$j" || continue
			pwd

			if [ ! -d root ]; then
				echo "wrong directory $i_base/$j!" >&2
				cd "$DIR" || exit 1
				continue
			fi

			outdir="calib-${n}_$p$s_name$only_min$only_max$ancient"
			rm -rf "$outdir"

			ruby "$PCD" \
				--indir root/ \
				--outdir "$outdir" \
				--run_mcmctree \
				--num "$n" \
				-p "$p" \
				-s "$s" \
				--force \
				--cpu "$cpu" \
				$only_min $only_max $ancient >/dev/null

			cd - >/dev/null || exit 1
		done
	) &

	((running++))
	if (( running >= jobs )); then
		wait -n
		((running--))
	fi
done

wait


