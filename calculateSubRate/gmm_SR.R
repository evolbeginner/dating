#! /bin/env Rscript


########################################################
library(ClusterR)


########################################################
args = commandArgs(trailingOnly=TRUE)

infile = args[1]
n = as.integer(args[2])


########################################################
# functions
find_index <- function(x){m = matrix(x, ncol=n); index = apply(m, 1, max); which(m==index)};


########################################################
a = read.table(infile)
b <- unlist(a$V2)

gmm = GMM(as.matrix(b), n)
#gmm = GMM(as.matrix(c(1,2,3,4,5)), n)


########################################################
grp <- apply(gmm$Log_likelihood, 1, find_index)

new = cbind(a, grp)

for(i in 1:n){
	cat(as.vector(new[new$grp == i, ]$V1), sep="\t")
	cat("\n")
}


