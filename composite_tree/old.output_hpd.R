#! /usr/bin/env Rscript


##################################################
library(BayesTwin)
library(stringr)


##################################################
args=commandArgs(T)
infiles = c()


##################################################
for(index in 1:length(args)){
	infiles[index] = args[index];
}


d1 = read.table(infiles[1], header=TRUE)
d = d1

for(index in 2:length(infiles)){
	print(index)
	d_new = read.table(infiles[index], header=TRUE)
	d = rbind(d_new, d)
}

for (i in colnames(d)){
	#if(grep("t_n[0-9]+", "123", perl=T)){print(7)}
	if(grepl("t_n[0-9]+", i, perl=T)){
		a = str_match(i, "t_n([0-9]+)")
		str = a[,2]
		hpd_int = HPD(d[[i]])
		mean = mean(d[[i]])
		cat(str, mean, hpd_int,"\n", sep="\t")
	}
}


