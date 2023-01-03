#! /usr/bin/env Rscript


##################################################
library(BayesTwin)
library(stringr)


##################################################
args=commandArgs(T)
infiles = c()


##################################################
d = read.table(args[1], header=TRUE, encoding="utf-8")

for (i in colnames(d)){
	#if(grep("t_n[0-9]+", "123", perl=T)){print(7)}
	if(grepl("t_n[0-9]+", i, perl=T)){
		a = str_match(i, "t_n([0-9]+)")
		str = a[,2]
		hpd_int = HPD(d[[i]])
		mean = mean(d[[i]])
		cat(str, mean, hpd_int, "\n", sep="\t")
	}
}


