#! /bin/env Rscript

library(coda)
library(data.table)

args <- commandArgs(T)

df <- data.frame()
for(i in args){
	infile <- i
	if(i == '-'){
		infile <- file("stdin")
	}
	tryCatch( {d <- read.csv(infile, header=T, sep="\t")}, error=function(e){print(e)})
	#d <- fread(i, sep="\t", data.table=F)
	d <- d[1:nrow(d)-1,]
	df <- rbind(df, d)
}

df <- df[,-1] # delete the last col (lnL)

# extract only t_nXXX
df <- df[names(df[grep("t_n", names(df))])]
df <- df[grep("t_n", names(df))]

tryCatch( { sapply(df, FUN=function(x){ess <- coda::effectiveSize(x); }) }, error=function(e){print(e); cat("probably infile csv error!", fill=T)})
q()

ess=coda::effectiveSize(df$lnL); print(ess)

#lapply(df, coda::effectiveSize)

for(i in colnames(df)){
	ess=coda::effectiveSize(df[[i]])
	print(ess)
}

