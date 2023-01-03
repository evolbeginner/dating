#! /bin/env Rscript

library(coda)
library(data.table)

args <- commandArgs(T)

df <- data.frame()
for(i in args){
	d <- read.csv(i, header=T, sep="\t")
	#d <- fread(i, sep="\t", data.table=F)
	d <- d[1:nrow(d)-1,]
	df <- rbind(df, d)
}

df <- df[,-1] # delete the last col (lnL)

# extract only t_nXXX
df <- df[names(df[grep("t_n", names(df))])]
df <- df[grep("t_n", names(df))]

sapply(df, FUN=function(x){ess <- coda::effectiveSize(x); })
#ess=coda::effectiveSize(df[,2]); print(ess); 
#ess=coda::effectiveSize(df[,3]); print(ess); 
q()

ess=coda::effectiveSize(df$lnL); print(ess)

#lapply(df, coda::effectiveSize)

for(i in colnames(df)){
	ess=coda::effectiveSize(df[[i]])
	print(ess)
}

