#! /bin/env bash


###########################################################
infile="scripts/2_mcmc_dating-1.rev"

a=(2 3 4)


###########################################################
for i in ${a[@]}; do
	outfile=${infile/-1/-$i}
	cp $infile $outfile 
	case $i in
		2)
			sed -i 's/constrain = .\+/constrain = true/' $outfile	
			;;
		3)
			sed -i 's/^constrain = .\+/constrain = true/' $outfile
			sed -i 's/\"root\"/\"rep.root\"/' $outfile
			;;
		4)
			sed -i 's/\"root\"/\"rep.root\"/' $outfile
			;;
	esac
done


