#! /usr/bin/env Rscript


#####################################################
library(getopt)
library(ape)
library(phangorn)


#####################################################
getMaxNodeToTip <- function(t){
	sapply((t$Ntip+1):(t$Nnode+t$Ntip), function(x){ max(sapply(Descendants(t, x)[[1]], function(y){ length(nodepath(t,from=x,to=y)) } ) ) })
}


getCdf <- function(minmax, cutoff, type){
	min <- minmax[1]
	max <- minmax[2]
	m <- mean(c(min, max))
	std <- abs(m-min)/1.96
	a <- sqrt(cutoff)
	if(type == 'norm'){
		return( c(qnorm(1-a,m,std), qnorm(a,m,std)) )
	} else if (type == 'unif'){
		return( c(qunif(1-a,min,max), qunif(a,min,max)) )
	}
}


isCalibOverlap <- function(calibs, cutoff, type){
	distr.minmax <- lapply( calibs, function(x){ as.double(strsplit(x,'-')[[1]]) } )
	distr <- lapply(distr.minmax, getCdf, cutoff=cutoff, type=type)
	return ( ifelse( ( distr[[1]][1] > distr[[2]][2] ), T, F) )
}


#####################################################
t <- NULL
prop <- 0.1
cutoff <- 0.1
type <- 'norm'


#####################################################
spec = matrix(c(
	'tree', 't', 2, 'character',
	'cutoff', 'c', 2, 'double',
	'type', 'y', 2, 'character',
	'prop', 'p', 2, 'double'),
	byrow=T, ncol=4
)
opt <- getopt(spec)

if(! is.null(opt$tree)){
	t <- read.tree(opt$tree)
} else{
	stop("tree must be given! Exiting ......")
}

if(! is.null(opt$cutoff)){
	cutoff <- opt$cutoff
}

if(! is.null(opt$type) ){
	type <- opt$type
}

if(! is.null(opt$prop)){
	prop <- opt$prop
}


#####################################################
t$Ntip <- length(t$tip.label)

a <- getMaxNodeToTip(t)

node2numOfTip <- list()

for( i in (t$Ntip+1):(t$Nnode+t$Ntip) ){
	node2numOfTip <- append( node2numOfTip, a[i-t$Ntip] )
}
names( node2numOfTip ) <- (t$Ntip+1):(t$Nnode+t$Ntip)

# to do order
node2numOfTip <- node2numOfTip [ order(unlist(node2numOfTip)) ]


for(i in names(node2numOfTip)){
	calibs <- character(2)
	i <- as.integer(i)
	parent <- Ancestors(t, i, type = "parent")	
	
	if(parent == 0){next}

	calibs <- lapply(c(i,parent), function(x){t$node.label[x-t$Ntip]})

	if ( any(calibs == '') ) {next}

	if (isCalibOverlap(calibs, cutoff, type)){
		t$node.label[parent-t$Ntip] <- ''
	}
}

write.tree(t, file='')


