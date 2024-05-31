#! /bin/env Rscript


#################################################
library(getopt)
library(this.path)
library(castor)
library(phytools)

DIR <- dirname(this.path()[1])
#source( file.path(DIR, 'convergence_plot.R') )


#################################################
get_all_node_ages <- function(t) {
 	#t <- read.tree(treefile)
	all_dist_to_root = get_all_distances_to_root(t, as_edge_count=FALSE)
	root_age <- all_dist_to_root[1]
	ages <- root_age - all_dist_to_root[-(1:(t$Nnode+1))]
}


#################################################
opt <- getopt(
	matrix(
		c(
			'in1', 'i', 1, 'character',
			'in2', 'j', 1, 'character',
			'out', 'o', 1, 'character'
		), ncol=4, byrow=T
	)
)

treefiles <- vector()
treefiles[1] <- opt$in1
treefiles[2] <- opt$in2
outfile <- opt$out


#################################################
ages <- list()


#################################################
ts <- lapply(treefiles, function(t){read.tree(t)})

for(j in 1:2){
	ages[[j]] <- get_all_node_ages(ts[[j]])
}

pdf(outfile)
plot(ages[[1]], ages[[2]], xlab="", ylab="", col="blue", cex=0.3)
abline(a = 0, b = 1, col = "grey")
dev.off()


