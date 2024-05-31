#! /bin/bash


#####################################################
simulated_tree_dir=''
sl=1000
cpu=4
scale=1

# time unit 100 Ma
birth=0.4
death=0.2
rho=0.1
ntips=30
age=10

mu=-3.7 # mu for lnorm
sd=0.2 # sd for lnorm

sim_model=LG+G+C20

bsn=100000,5,100000

is_stop_compare=false


#####################################################
while [ $# -gt 0 ]; do
	case $1 in
		--simulated_tree_dir)
			simulated_tree_dir=$2
			shift
			;;
		--sl)
			sl=$2
			shift
			;;
		--cpu)
			cpu=$2
			shift
			;;
		--scale)
			scale=$2
			shift
			;;
		--birth)
			birth=$2
			shift
			;;
		--death)
			death=$2
			shift
			;;
		--age)
			age=$2
			shift
			;;
		--rho)
			rho=$2
			shift
			;;
		--ntips)
			ntips=$2
			shift
			;;
		--mu)
			mu=$2
			shift
			;;
		--sd)
			sd=$2
			shift
			;;
		--sim_model)
			sim_model=$2
			shift
			;;
		--bsn)
			bsn=$2
			shift
			;;
		--stop_compare)
			is_stop_compare=true
			;;
		*)
			echo "Wrong argument $1!" >&2
			exit 1
			;;
	esac
	shift
done


#####################################################
mkdir -p sim/tree
if [ -d "$simulated_tree_dir" ]; then
	cp $simulated_tree_dir/time.tre sim/tree
	Rscript ~/project/Rhizobiales/scripts/dating/hessian/sim_tree.R -n $ntips -m $mu --sd $sd -o sim/tree --timetree sim/tree/time.tre
else
	Rscript ~/project/Rhizobiales/scripts/dating/hessian/sim_tree.R -n $ntips -m $mu --sd $sd -b $birth -d $death --age $age --rho $rho -o sim/tree
fi


#####################################################
# generate aln
bash ~/project/Rhizobiales/scripts/dating/hessian/do_iqtree_sim_mcmctree.sh --force --outdir sim/alignment/ --indir sim/tree/ -m $sim_model --length $sl


#####################################################
# ori ncatG=4
ruby ~/project/Rhizobiales/scripts/dating/do_mcmctree.rb --outdir dating/ori --tree_indir sim/alignment/ -i sim/alignment/combined.phy --force --prot --clock IR --bsn $bsn; mv dating/ori/combined dating/ori/mcmctree; sed '4!d' dating/ori/mcmctree/in.BV > ref.tre

# ori ncatG=0
ruby ~/project/Rhizobiales/scripts/dating/do_mcmctree.rb --outdir dating/ori_woG --tree_indir sim/alignment/ -i sim/alignment/combined.phy --force --prot --clock IR --bsn $bsn --ncatG 0; mv dating/ori_woG/combined dating/ori_woG/mcmctree

# LG
model=LG
echo $model
ruby ~/project/Rhizobiales/scripts/dating/hessian/create_hessian_by_bootstrapping.rb --ali sim/alignment/combined.phy --ref ref.tre --outdir dating/$model --force -b 1000 --cpu $cpu -m $model --mcmctree_ctl dating/ori/mcmctree/mcmctree.ctl --calibrated_tree sim/alignment/species.trees --run_mcmctree

# LG+G
model=LG+G
echo $model
ruby ~/project/Rhizobiales/scripts/dating/hessian/create_hessian_by_bootstrapping.rb --ali sim/alignment/combined.phy --ref ref.tre --outdir dating/$model --force -b 1000 --cpu $cpu -m $model --mcmctree_ctl dating/ori/mcmctree/mcmctree.ctl --calibrated_tree sim/alignment/species.trees --run_mcmctree

[ $is_stop_compare == true ] && exit

# LG+C20+G
model=LG+C20+G
echo $model
ruby ~/project/Rhizobiales/scripts/dating/hessian/create_hessian_by_bootstrapping.rb --ali sim/alignment/combined.phy --ref ref.tre --outdir dating/$model --force -b 1000 --cpu $cpu -m $model --mcmctree_ctl dating/ori/mcmctree/mcmctree.ctl --calibrated_tree sim/alignment/species.trees --run_mcmctree


# LG+C40+G
model=LG+C40+G
echo $model
ruby ~/project/Rhizobiales/scripts/dating/hessian/create_hessian_by_bootstrapping.rb --ali sim/alignment/combined.phy --ref ref.tre --outdir dating/$model --force -b 1000 --cpu $cpu -m $model --mcmctree_ctl dating/ori/mcmctree/mcmctree.ctl --calibrated_tree sim/alignment/species.trees --run_mcmctree


############################################
exit


############################################
# LG*H4
model=LG*H4
ruby ~/project/Rhizobiales/scripts/dating/hessian/create_hessian_by_bootstrapping.rb --ali sim/alignment/combined.phy --ref ref.tre --outdir dating/H4 --force -b 1000 --cpu $cpu -m $model --mcmctree_ctl dating/ori/mcmctree/mcmctree.ctl --calibrated_tree sim/alignment/species.trees --run_mcmctree

# LG4M
model=LG4M
ruby ~/project/Rhizobiales/scripts/dating/hessian/create_hessian_by_bootstrapping.rb --ali sim/alignment/combined.phy --ref ref.tre --outdir dating/$model --force -b 1000 --cpu $cpu -m $model --mcmctree_ctl dating/ori/mcmctree/mcmctree.ctl --calibrated_tree sim/alignment/species.trees --run_mcmctree

# LG+EHO+G
model=LG+EHO+G
ruby ~/project/Rhizobiales/scripts/dating/hessian/create_hessian_by_bootstrapping.rb --ali sim/alignment/combined.phy --ref ref.tre --outdir dating/$model --force -b 1000 --cpu $cpu -m $model --mcmctree_ctl dating/ori/mcmctree/mcmctree.ctl --calibrated_tree sim/alignment/species.trees --run_mcmctree
