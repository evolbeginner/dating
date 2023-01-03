#! /bin/bash

for i in `find -name FigTree.tre`; do
	d=`dirname $i`
	bash ~/project/Rhizobiales/scripts/dating/figtree2tree.sh -i $d/FigTree.tre > $d/figtree.nwk
done
