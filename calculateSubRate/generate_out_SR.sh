for i in `ls *out`; do b=`basename $i`; c=${b%%.*}; a=`grep 'Substitution rate' -A1 $i | tail -1 | awk '{print $1}'`; echo -e "$c\t$a"; done > out_SR
