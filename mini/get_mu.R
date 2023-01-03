#! /bin/env Rscript


args <- commandArgs(trailingOnly = TRUE)

n = as.integer(args[2])

d = read.table(args[1], header=T, nrows=4500)

if(n == 5){
	c = matrix(c(d$mu1, d$mu2, d$mu3, d$mu4, d$mu5), ncol=n)
} else if(n == 3){
	c = matrix(c(d$mu1, d$mu2, d$mu3), ncol=3)
} else if(n == 2){
	c = matrix(c(d$mu1, d$mu2), ncol=n)
}

root_mean = apply(matrix(c(d$t_n205, d$t_n281), ncol=2), 2, mean)
mu_means = apply(c, 2, mean)

print(root_mean)
print(mu_means)


