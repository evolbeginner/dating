#! /usr/bin/env Rscript


#####################################################
suppressWarnings({
    library(getopt)
    library(ape)
})


#####################################################
get_calib_interval <- function(x, percent=0.2, sp=0){
	bottom <- round(x * (1-percent+sp), 5)
	top <- round(x * (1+percent+sp), 5)
	return(c(bottom, top))
}


#####################################################
#args <- commandArgs(TRUE)
treefile <- NULL
outfile <- NULL
percent <- 0.2
shift_percent <- 0
num <- 2
is_only_min <- F
is_only_max <- F


#####################################################
command=matrix(c( 
    'tree', 't', 2, 'character',
    'outfile', 'o', 2, 'character',
    'num', 'n', 2, 'integer',
    'only_min', 'm', 0, 'logical',
    'only_max', 'M', 0, 'logical',
    'shift', 's', 2, 'double',
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
if(! is.null(args$only_max)){
	is_only_max <- T
}
if(! is.null(args$shift)){
	shift_percent <- args$shift
}
if(! is.null(args$percent)){
	percent <- args$percent
}

#print(percent)
#percent <- sapply( 1:length(percent), function(i){shift_percent[i] + percent[i]} )


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


# for uniform only_min
max_age <- NULL
age <- d[d.order[nodes[length(nodes)][[1]]]]
ages <- get_calib_interval(age, percent, shift_percent)
max_age <- ages[2]

c <- 0
for(i in nodes){
	c <- c + 1
	age <- d[d.order[i]]
	index <- d.order[i]
	#print(index)
	#d[d.order[20]] <- paste('>', d[d.order[20]]-, )
	ages <- get_calib_interval(age, percent, shift_percent)
	if(is_only_min && c < length(nodes)){
		tree$node.label[index] <- paste(">", ages[1], sep="")
		#tree$node.label[index] <- paste(">", ages[1], '<', max_age, sep="")
    } else if(is_only_max){
		tree$node.label[index] <- paste("<", ages[2], sep="")
	} else{
		tree$node.label[index] <- paste(">", ages[1], "<", ages[2], sep="")
	}
}

a <- write.tree(tree)

a <- gsub(")NA", ')', a)

cat(a,"\n")


