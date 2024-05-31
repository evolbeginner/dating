#! /bin/env Rscript


#####################################################
library(getopt)
library(phytools)
library(castor)


#####################################################
parse_infile <- function(infile){
	name2treefiles <- list()
	d <- read.table(infile, header=F, stringsAsFactors = FALSE, sep="\t")
	d <- d[!grepl("^#", d$V1), ]
	d <- d[!d$V1 == "", ]
	unique_names <- unique(d$V1)
	for (name in unique_names) {
		treefiles <- d[ d$V1 == name, ]$V2
		a <- list(name = name, treefiles = treefiles)
		name2treefiles[[ length(name2treefiles) + 1 ]] <- a
	}
	return(name2treefiles)
}


get_all_node_ages <- function(t) {
 	#t <- read.tree(treefile)
	all_dist_to_root = get_all_distances_to_root(t, as_edge_count=FALSE)
	root_age <- all_dist_to_root[1]
	ages <- root_age - all_dist_to_root[-(1:(t$Nnode+1))]
}


#####################################################
outfile <- NULL
nrow_plot <- 1
ncol_plot <- 1


#####################################################
spec <- matrix(
	c(
		"infile", "i", 2, "character",
		"outfile", "o", 2, "character",
		"nrnc", "n", 2, "character"
	), ncol=4, byrow=T
)

args <- getopt(spec)

if(!is.null(args$infile)){
	name2treefiles <- parse_infile(args$infile)
	#print(name2treefiles); q()
}

if(!is.null(args$outfile)){
	outfile <- args$outfile
}

if(! is.null(args$nrnc)){
	a <- as.numeric(unlist(strsplit(args$nrnc, ',')))
	nrow_plot <- a[1]
	ncol_plot <- a[2]
}


#####################################################
pdf(outfile, width = 8.27, height = 11.69)

par(mfrow=c(nrow_plot, ncol_plot), mai=rep(0.5,4))

for (i in 1:length(name2treefiles)){
	ages <- list()
	#print(name2treefiles); q()

	obj <- name2treefiles[[i]]

	ts <- lapply(obj$treefiles, function(t){read.tree(t)})
	for(j in 1:2){
		ages[[j]] <- get_all_node_ages(ts[[j]])
	}
	plot(ages[[1]], ages[[2]], main=obj$name, xlab="", ylab="", col="blue", cex=0.3)
	abline(a = 0, b = 1, col = "grey")
}

dev.off()


