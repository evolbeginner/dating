#! /bin/bash Rscript


########################################################
# 2025-02-11
# changed to mclust


########################################################
library(mclust)


########################################################
args = commandArgs(trailingOnly=TRUE)

infile = args[1]
n = as.integer(args[2])

########################################################
# functions
find_index <- function(x) {
  m = matrix(x, ncol=n)
  index = apply(m, 1, max)
  which(m == index)
}

########################################################
a = read.table(infile)
b <- unlist(log(a$V2))

# Fit GMM using mclust
gmm <- Mclust(as.matrix(b), G = n)

########################################################
# Get the cluster assignments
grp <- gmm$classification

new = cbind(a, grp)

for(i in 1:n) {
  cat(as.vector(new[new$grp == i, ]$V1), sep="\t")
  cat("\n")
}


