#! /bin/env Rscript


###########################################
library(phytools)
library(getopt)


###########################################
infile <- NULL
outfile <- NULL
fsize <- 0.2


###########################################
command=matrix(c( 
	'infile', 'i', 2, 'character',
	'outfile', 'o', 2, 'character'
	), byrow=T, ncol=4
)
args=getopt(command)

if(! is.null(args$infile)){
	infile <- args$infile
}else{
	stop("infile not given!")
}

if(! is.null(args$outfile)){
	outfile <- args$outfile
}else{
	stop("outfile not given!")
}


###########################################
t <- read.tree(infile)

pdf(outfile)

plotTree(t, fsize=fsize)

nodelabels(cex=fsize*2)

dev.off()


