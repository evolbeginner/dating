#! /bin/bash


##################################################################
infile=''
subtree_file=''
include_list_file=''


##################################################################
while [ $# -gt 0 ]; do
	case $1 in
		-i)
			infile=$2
			shift
			;;
		--subtree)
			subtree_file=$2
			shift
			;;
		--include_list)
			include_list_file=$2
			shift
			;;
		*)
			echo "unknown param $1" >&2
			exit 1
			;;
	esac
	shift
done


##################################################################
if [ ! -f "$infile" -o ! -f $subtree_file ]; then
	echo "infile $infile or subtree_file ${subtree_file} not found! Exiting ......" >&2
	exit 1
fi


##################################################################
perl  ~/project/Rhizobiales/scripts/dating/calib/change_species_tree_skew_calib.pl --tree $infile --convert 1 > species.trees_change

if [ -f "$include_list_file" ]; then
	nw_prune -vf species.trees_change $include_list_file | sponge species.trees_change
fi

bash ~/project/Rhizobiales/scripts/dating/pipe/replace_euk_subtree.sh species.trees_change $subtree_file > species.trees_change2

perl ~/project/Rhizobiales/scripts/dating/calib/change_species_tree_skew_calib.pl --tree species.trees_change2 --convert 2 > species.trees

no_taxa=`perl ~/project/Rhizobiales/scripts/dating/calib/change_species_tree_skew_calib.pl --tree species.trees_change2 --convert 1 | nw_stats - | grep leaves | awk '{print $2}'`
echo -e "$no_taxa\t1" | cat - species.trees | sponge species.trees

