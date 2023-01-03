# /bin/bash

################################
DIR=`dirname $0`


################################
infile=''
outfile=''
burnin=2


################################
while [ $# -gt 0 ]; do
	case $1 in
		-i)
			infile=$2
			shift
			;;
		-o)
			outfile=$2
			shift
			;;
		--burnin)
			burnin=$2
			shift
			;;
		*)
			echo "Wrong param $1" >&2
			exit 1
			;;
	esac
	shift
done


################################
if [ -z $outfile ] || [ -z $infile ]; then
	echo "infile or outfile not given! Exiting ......" >&2
	exit 1
fi


################################
sed 's!out_bn = .\+!out_bn = \"'$infile'\"!' -i $DIR/mcc.Rev

#revbayes $DIR/mcc.Rev | tail -1 > $outfile
tmp_mcc=/tmp/"$$"mcc.Rev
cp $DIR/mcc.Rev $tmp_mcc
if [ $burnin -ne 2 ]; then sed -i "s/burnin=./burnin=$burnin/" $tmp_mcc; fi
revbayes $tmp_mcc | tail -1 > $outfile
rm $tmp_mcc

echo "END;" >>  $outfile


################################
r_file=/tmp/$$.txt # create a tmpfile

tac $outfile > $r_file

echo "Begin trees;" >> $r_file

echo "" >> $r_file

echo "#NEXUS" >> $r_file

tac $r_file > $outfile

rm $r_file

sed -i 's/^ \+/tree TREE1 = /' $outfile

