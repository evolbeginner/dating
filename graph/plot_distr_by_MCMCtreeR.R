#! /bin/env Rscript


########################################
library(getopt)
library(MCMCtreeR)

source("~/project/Rhizobiales/scripts/dating/graph/uniformMCMCtree.my.R")
assignInNamespace("uniformMCMCtree", uniformMCMCtree, "MCMCtreeR")


########################################
infile <- NA
xmax <- 4


########################################
spec <- matrix(c(
	'infile', 'i', 2, 'character',
	'outfile', 'o', 2, 'character',
	'xmax', 'm', 2, 'numeric'
), ncol=4, byrow=T)

opt = getopt(spec)

if(!is.null(opt$infile)){
	infile <- opt$infile
}
if(!is.null(opt$outfile)){
	outfile <- opt$outfile
}
if(!is.null(opt$xmax)){
	xmax <- opt$xmax
}


########################################
d <- read.table(infile, header=T)

pdf(outfile)

par(mfrow=c(ceiling(nrow(d)/4), 4))

########################################
for(i in 1:nrow(d)){
	obj <- d[i,]
	print(obj[2:5])
	plotMCMCtree(obj[2:5], method = obj$method, title = paste0("node ", obj$node), upperTime = xmax, plotMCMCtreeData=T)
}

dev.off()


