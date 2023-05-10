#! /bin/bash


##################################################
infiles=()


##################################################
while [ $# -gt 0 ]; do
	case $1 in
		-)
			infiles=(${infiles[@]} -)
			;;
		*)
			infiles=(${infiles[@]} $1)
			;;
	esac
	shift
done


##################################################
h=`head -1 ${infiles[0]}`
echo $h | sed 's/ /\t/g'
cat ${infiles[@]} | sed '/^Gen/d' | awk 'BEGIN{OFS="\t"; c=1}{if(NR==1){nf=NF}; if(NF==nf){$1=c++; print}}'


exit
sed '$d' ${infiles[0]} | awk 'BEGIN{OFS="\t"; c=1}{if(NR>=2){$1=c++}print}'

len=${#infiles[@]}
for (( i=1; i<$len; i++ )); do
	sed '1,$d' ${infiles[$i]} | awk 'BEGIN{OFS="\t"; c=1}{if(NR>=2){$1=c++}print}'
done


