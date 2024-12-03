#! /usr/bin/env Rscript


#####################################################
suppressWarnings({
    library(getopt)
    library(ape)
})


#####################################################
get_calib_interval <- function(x, y=0.2){
	# y: percent
	bottom <- round(x * (1-y), 5)
	top <- round(x * (1+y), 5)
	return(c(bottom, top))
}


#####################################################
#args <- commandArgs(TRUE)
treefile <- NULL
outfile <- NULL
percent <- 0.2
num <- 2
is_only_min <- F


#####################################################
command=matrix(c( 
    'tree', 't', 2, 'character',
    'outfile', 'o', 2, 'character',
    'num', 'n', 2, 'integer',
    'only_min', '', 0, 'logical',
    'percent', 'p', 2, 'double'),
    byrow=T, ncol=4
)
args=getopt(command)

if(! is.null(args$tree)){
	treefile <- args$tree
}
if(! is.null(args$outfile)){
	outfile <- args$outfile
}
if(! is.null(args$num)){
	# num of internal calibs (in addition to root)
	num <- args$num
}
if(! is.null(args$only_min)){
	is_only_min <- T
}
if(! is.null(args$percent)){
	percent <- args$percent
}


#####################################################
tree <- ape::read.tree(treefile) # read a timetree

root_no <- length(tree$tip.label) + 1

d <- dist.nodes(tree)[root_no, 1] - dist.nodes(tree)[root_no, (root_no):(root_no+tree$Nnode-1)]

d.order <- order(d)

#tree$node.label <- vector(mode="character")
tree$node.label <- vector(mode="character")
tree$node.label <- rep("NA", length(tree$tip.label))


#####################################################
# if n = 2, that is 1/3, 2/3, root
nodes <- lapply(1:num, FUN=function(x){ floor( x/(num+1) * length(tree$tip.label) ) } )
nodes <- append(nodes, length(tree$tip.label)-1)

c <- 0
for(i in nodes){
	c <- c + 1
	age <- d[d.order[i]]
	index <- d.order[i]
	#print(index)
	#d[d.order[20]] <- paste('>', d[d.order[20]]-, )
	ages <- get_calib_interval(age, percent)
	if(is_only_min && c < length(nodes)){
		tree$node.label[index] <- paste(">", ages[1], sep="")
	} else{
		tree$node.label[index] <- paste(">", ages[1], "<", ages[2], sep="")
	}
}

a <- write.tree(tree)

a <- gsub(")NA", ')', a)

cat(a,"\n")


