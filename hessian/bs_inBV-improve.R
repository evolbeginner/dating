#! /bin/env Rscript


############################################
suppressWarnings(library(getopt))


############################################
read_hessian_from_inBV <- function(infile){
    lines <- readLines(infile)
  
    # Find Hessian block
    hessian_start <- which(lines == "Hessian") + 1
    hessian_end <- length(lines)
    empty_lines <- which(lines == "" | grepl("^\\s*$", lines))

    if (any(empty_lines > hessian_start)) {
        hessian_end <- min(empty_lines[empty_lines > hessian_start]) - 1
    }

    hessian_lines <- lines[hessian_start:hessian_end]
    hessian <- do.call(rbind, lapply(strsplit(trimws(hessian_lines), "\\s+"), as.numeric))
    hessian <- hessian[complete.cases(hessian), , drop = F]

    return(hessian)
}


get_X <- function(H_bs, H_fd, n_train, type1='full', type2='sum'){
    X <- H_bs; X[] <- 0
    Xs <- list()
    sum1 <- 0
    sum2 <- 0

    if(type1 == 'full'){
        for(i in 1:n_train){
            if(type2 == 'sum'){
                sum1 <- sum1 + H_bs[[i]] %*% H_bs[[i]]
                sum2 <- sum2 + H_bs[[i]] %*% H_fd[[i]]
            } else{
                sum1 <- H_bs[[i]] %*% H_bs[[i]]
                sum2 <- H_bs[[i]] %*% H_fd[[i]]
                Xs[[i]] <- solve(sum1) %*% sum2
            }
        }
        X <- finally_get_X(type2, sum1, sum2, Xs)
    } else if(type1 == 'one'){
        for(i in 1:n_train){
            if(type2 == 'sum'){
                sum1 <- sum1 + sum(diag(H_bs[[i]] %*% H_bs[[i]]))
                sum2 <- sum2 + sum(diag(H_bs[[i]] %*% H_fd[[i]]))
            } else{
                sum1 <- sum(diag(H_bs[[i]] %*% H_bs[[i]]))
                sum2 <- sum(diag(H_bs[[i]] %*% H_fd[[i]]))
                Xs[[i]] <- diag(1/sum1*sum2, ncol(H_bs[[1]]))
            }
        }
        if(type2 == 'sum'){
            sum1 <- diag(sum1, ncol(H_bs[[1]]))
            sum2 <- diag(sum2, ncol(H_bs[[1]]))
        }
        X <- finally_get_X(type2, sum1, sum2, Xs)
    }
    return(X)
}


############################################
finally_get_X <- function(type2, sum1, sum2, Xs){
    if(type2 == 'sum'){
        X <- solve(sum1) %*% sum2
    } else {
        X <- Reduce(`+`, Xs)/length(Xs)
    }
}


frobenius_dist <- function(A, B) {
  sqrt(sum((A - B)^2))
}


############################################
spec <- matrix(c(
    "type1", "T", 1, "character", "full, one",
    "type2", "t", 1, "character", "sum, avg",
    "help",  "h", 0, "logical",   "Print help message and exit"
), byrow=T, ncol=5)

opt <- getopt(spec)
if (! is.null(opt$type1)) {
    type1 <- opt$type1
} else{
    stop('--type1 must be specified')
}

if(! is.null(opt$type2)){
    type2 <- opt$type2
} else{
    stop('--type2 must be specified')
}


############################################
# Initialize empty list to store Hessian matrices
H_fd <- list()
H_bs <- list()

# Get all file paths matching the pattern
file_fd_paths <- Sys.glob("haha/*/mcmctree/combined/in.BV")
file_bs_paths <- Sys.glob("haha/*/bs_inBV/mcmctree/in.BV")

# Loop through each file
n <- length(file_bs_paths)
for (i in 1:n) {
    H_fd[[i]] <- read_hessian_from_inBV(file_fd_paths[i])
    H_bs[[i]] <- read_hessian_from_inBV(file_bs_paths[i])
}


############################################
sum1=0
sum2=0
n_train <- round(n*0.33)
#n_train <- 10
trains <- 1:n_train
tests <- setdiff(1:n, 1:n_train)
#tests <- 1:10

X <- get_X(H_bs, H_fd, n_train, type1=type1, type2=type2)

for(i in tests){
    f0 <- frobenius_dist(H_bs[[i]], H_fd[[i]])
    f1 <- frobenius_dist(H_bs[[i]]%*%X, H_fd[[i]])
    cat(i, f0, f1, "\n", sep="\t")
}


