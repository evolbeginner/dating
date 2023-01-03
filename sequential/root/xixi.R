#! /bin/env Rscript


#############################################
library(getopt)
library(sn)
library(fitdistrplus)


#############################################
command = matrix(c( 
    'input', 'i', 2, 'character',
    'output', 'o', 2, 'character',
    'type', 't', 2, 'character'),
    byrow=T, ncol=4
)
args=getopt(command)


#############################################
input = args$input
type = args$type


#############################################
m <- read.table(input, header=T)
#m <- m[,-which(names(m) %in% c('lnL'))]
#m <- m[, -1]


#############################################
if(type == 'st'){
	res <- sapply(m, function(y)st.mple(y=y)$dp)
}


#############################################
if(is.null(args[["output"]])){
	write.table(t(res), col.names=T, sep="\t", quote=F)
} else{
	write.table(t(res), file=args$output, col.names=T, sep="\t", quote=F)
}


