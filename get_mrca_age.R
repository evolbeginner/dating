#! /bin/env Rscript


###########################################################
library(phytools)
library(getopt)


###########################################################
get_age <- function(taxa_pair){
	taxa <- strsplit(taxa_pair, ',')[[1]]
	lca <- getMRCA(tree, taxa)
	dist_to_root <- node.depth.edgelength(tree)
	root_age <- dist_to_root[1]
	# dist_to_root1[1] is tip-to-root distance for tree
	age <- root_age - dist_to_root[lca]
	cat(taxa_pair, age, "\n", sep="\t")
}


###########################################################
opt <- getopt(
	matrix(
		c(
			'tree', 't', 1, 'character',
			'taxa', 'T', 1, 'character'
		), ncol=4, byrow=T
	)
)

tree <- read.tree(opt$tree)
taxa_pairs <- unlist(strsplit(opt$taxa, ":"))
taxa <- sapply(taxa_pairs, get_age)


