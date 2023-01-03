# /bin/env bash


###############################################
include_list=$1


###############################################
for i in ./species.trees*; do
	echo $i
	b=`basename $i`
	new_tree=./$b
	#echo "sed '1d' $i | nw_prune -v - -f $include_list > $new_tree"; exit
	sed '1d' $i | nw_prune -v - -f $include_list | sponge $new_tree
	no_of_species=`nw_stats $new_tree | grep 'leaves'|cut -f 2`
	echo -e "$no_of_species\t1" | cat - $new_tree | sponge $new_tree
done
