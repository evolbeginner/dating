#! /bin/env Rscript

library(coda)
library(parallel)


############################################
byRow <- T


############################################
args <- commandArgs(T)

# Parse --threads / -j argument
n_threads <- 1
file_args <- c()
i <- 1
while(i <= length(args)) {
    if(args[i] == '-j' || args[i] == '--cpu') {
        n_threads <- as.integer(args[i + 1])
        i <- i + 2
    } else {
        file_args <- c(file_args, args[i])
        i <- i + 1
    }
}

df <- data.frame()
for(i in file_args){
    infile <- i
    if(i == '-'){
        infile <- file("stdin")
    }
    tryCatch( {d <- read.csv(infile, header=T, sep="\t")}, error=function(e){print(e)})
    d <- d[1:nrow(d)-1,]
    df <- rbind(df, d)
}

df <- df[,-1] # delete the last col (lnL)

# extract only t_nXXX
df <- df[names(df[grep("t_n", names(df))])]
df <- df[grep("t_n", names(df))]


if(byRow){
    column_names <- colnames(df)
    ess_values <- unlist(mclapply(column_names, function(col) {
        coda::effectiveSize(df[[col]])
    }, mc.cores = n_threads))

    cat(paste(column_names, collapse="\t"), "\n", paste(ess_values, collapse="\t"), "\n", sep="")
    q()
}


results <- mclapply(colnames(df), function(col) {
    ess <- coda::effectiveSize(df[[col]])
    c(col, ess)
}, mc.cores = n_threads)

for(r in results) {
    cat(r[1], "\t", r[2], "\n")
}

