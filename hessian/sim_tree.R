#! /usr/bin/env Rscript


###################################################
suppressPackageStartupMessages(
    suppressWarnings({
        library(ape)
        library(TreeSim)
        library(getopt)
        library(simclock)
        library(psych)
    })
)


###################################################
calculate_var_AR <- function(C) { n=nrow(C); ( sum(diag(C)) - 1/n * sum(C) ) / (n-1) }

vcv_branches <- function(tree) {
    node_dist_m <- mrca(tree, full=T)
    
    n_branches <- length(tree$edge.length)
    vcv_matrix <- matrix(0, n_branches, n_branches)
    
    # Calculate the distance from each node to the root
    node_depths <- node.depth.edgelength(tree)
    
    # Fill the diagonal with the distance to the root for the 2nd element of tree$edge
    m <- sapply(tree$edge[,2], function(x){node.depth.edgelength(tree)[x]})
    diag(vcv_matrix) = m
    
    # Fill the off-diagonal elements with the shared branch lengths
    for (i in 1:n_branches) {
        for (j in 1:n_branches) {
            if (i != j) {
                node1 <- tree$edge[i, 2]
                node2 <- tree$edge[j, 2]
                #mrca <- getMRCA(tree, c(node1, node2))
                lca <- node_dist_m[node1, node2]
                #print(c(node1, node2, lca))
                shared_distance <- node_depths[lca]
                vcv_matrix[i, j] <- shared_distance
            }
        }
    }
    
    return(vcv_matrix)
}


###################################################
mu <- -2.3 # corresponding to E(x) = 1
sd <- 0.2
s2 <- NULL

rho <- 0.01
age <- 10
clock <- 'IR'
#sd <- 0.5 # corresponding to Var(x) = 0.006^2


###################################################
command=matrix(c( 
    'help', 'h', 0, 'loical',
    'num', 'n', 2, 'integer',
    'birth', 'b', 2, 'numeric',
    'death', 'd', 2, 'numeric',
    'rho', 'r', 2, 'numeric',
    'age', 'a', 2, 'numeric',
    'mu', 'm', 2, 'numeric',
    'clock', 'c', 2, 'character',
    'sd', '', 2, 'numeric',
    's2', 'S', 2, 'numeric',
    'scale', 's', 2, 'numeric',
    'outdir', 'o', 2, 'character',
    'timetree', 't', 2, 'character'),
    byrow=T, ncol=4
)
args=getopt(command)


###################################################
# if not given will use the default
if(is.null(args[["scale"]])){
	scale <- 1
}else{
	scale <- args$scale
}

if(is.null(args[["mu"]])){
	mu <- mu
}else{
	mu <- args$mu
}

if(is.null(args[["sd"]])){
	sd <- sd
}else{
	sd <- args$sd
}

if(is.null(args[["s2"]])){
	s2 <- s2
}else{
	s2 <- args$s2
}

# if not given will exit!
if(is.null(args[["age"]])){
	print("age not given")
}else{
	age <- args$age
}

if(is.null(args[["rho"]])){
	print("rho not given")
}else{
	rho <- args$rho
}

if(! is.null(args[["clock"]])){
    clock <- args$clock
}




###################################################
birth <- args$birth
death <- args$death
n <- args$num

if (is.null(args[["timetree"]])){
	#tree <- rphylo(n, birth, death)
	trees <- sim.bd.taxa.age(n, 1, birth, death, rho, age, mrca = TRUE);
	timetree <- trees[[1]]
} else{
	timetree_infile = args$timetree
	timetree <- read.tree(timetree_infile)
}


# generate time tree
timetree$edge.length <- timetree$edge.length * scale


if (clock == 'AR' && is.null(s2)){
    #c <- vcv(timetree)
    c <- vcv_branches(timetree)
    s2 <- sd^2 / calculate_var_AR(c)
}
print(s2)


###################################################
# create sub tree
subs_tree <- timetree
if(clock == 'IR'){
    lnorm_rate <- rlnorm(length(subs_tree$edge.length), mu, sd)
    subs_tree$edge.length <- subs_tree$edge.length * lnorm_rate
}else if(clock == 'AR'){
    #s2 <- sd^2 / (tr(vcv(timetree)) - 0.5*sum(timetree$edge.length))
    subs_tree <- relaxed.tree(subs_tree, model="gbm", r=exp(mu), s2=s2)
}

# create unrooted tree
unrooted_tree <- unroot(subs_tree)

# create rate tree
rate_tree <- subs_tree
#rate_tree$edge.length <- lnorm_rate
rate_tree$edge.length <- subs_tree$edge.length/timetree$edge.length


###################################################
if(is.null(args[["outdir"]])){
	write.tree(timetree)
	write.tree(subs_tree)
}else{
	outdir <- args$outdir
	if (!dir.exists(outdir)) {dir.create(outdir)}

	subtree_file = file.path(outdir, "sub.tre")
	timetree_file = file.path(outdir, "time.tre")
    unrooted_tree_file = file.path(outdir, "unrooted.tre")
    rate_tree_file = file.path(outdir, "rate.tre")
	cmd_file = file.path(outdir, "cmd")

	write.tree(timetree, timetree_file)
	write.tree(subs_tree, subtree_file)
	write.tree(unrooted_tree, unrooted_tree_file)
	write.tree(rate_tree, rate_tree_file)
	#lapply(args, write, cmd_file, append=TRUE, ncolumns=1000)
}


