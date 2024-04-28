#! /bin/env Rscript


#############################################
library(phytools)
library(getopt)


#############################################
treefile <- NULL
tree_to_insert <- NULL

outfile <- NULL

is_mcmctree <- F # the 2nd is the newick-formatted tree
header_line <- NULL


#############################################
command = matrix(
	c(
		"tree", "t", 2, "character",
		"tree2", "", 2, "character",
		"out", "o", 2, "character",
		"where", "w", 2, "character",
		"mcmctree", "m", 0, "logical"
	), byrow=T, ncol=4
)

args = getopt(command)

if(!is.null(args$tree)){
	treefile = args$tree
} else {
	print("treefile must be imported by --tree")
	q()
}

if(!is.null(args$tree2)){
	tree_to_insert = read.tree(args$tree2)
} else{
	print("tree to insert must be imported by --tree2")
	q()
}

if(!is.null(args$out)){
	outfile <- args$out
}

if(!is.null(args$where)){
	where = as.character( unlist(read.table(args$where)) )
} else{
	print("where to insert tree2: --where")
	q()
}

if(!is.null(args$mcmctree)){
	is_mcmctree <- T
}

# Read only the second line of the file
if(is_mcmctree){
	treefile_lines <- readLines(treefile, n = 2)
	header_line <- treefile_lines[1]
	second_line <- treefile_lines[2]
	tree <- read.tree(text=second_line)
}else{
	tree <- read.tree(treefile)
}


#############################################
if(length(where)>=2){
	# if a clade
	node <- where
	parent_node <- getMRCA(tree, node)
} else {
	# tip
	parent_node <- which(tree$tip.label == where[1])
}

# new subtree (the tips to insert)
tree.new = bind.tree(tree, tree_to_insert, where=parent_node, position=1e-7)

tree.new$node.label[is.na(tree.new$node.label)] <- ""

#############################################
if(is_mcmctree){
	number <- as.numeric(strsplit(header_line, "\\s+")[[1]][1])
	new_number <- number + length(tree_to_insert$tip.label)
	new_header_line <- paste(new_number, strsplit(header_line, "\\s+")[[1]][2], sep = "\t")
	#new_header_line <- paste(new_number, substring(header_line, nchar(number) + 2), sep = "\t")
	cat(new_header_line); cat("\n")
}

#write.tree(tree.new, file=outfile)
cat(write.tree(tree.new)[1])
cat("\n")


