#! /usr/bin/env Rscript


###################################################
library(ape)
library(TreeSim)
library(getopt)


###################################################
mu <- -2.3 # corresponding to E(x) = 1
sd <- 0.2
rho <- 0.01
age <- 10
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
    'sd', '', 2, 'numeric',
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


###################################################
birth <- args$birth
death <- args$death
n <- args$num

if (is.null(args[["timetree"]])){
	#tree <- rphylo(n, birth, death)
	trees <- sim.bd.taxa.age(n, 1, birth, death, rho, age, mrca = TRUE);
	tree <- trees[[1]]
} else{
	timetree = args$timetree
	tree <- read.tree(timetree)
	#scale <- 1
}

tree$edge.length <- tree$edge.length * scale


###################################################
t <- tree

t$edge.length <- t$edge.length * rlnorm(length(t$edge.length), mu, sd);


###################################################
if(is.null(args[["outdir"]])){
	write.tree(tree)
	write.tree(t)
}else{
	outdir <- args$outdir
	if (!dir.exists(outdir)) {dir.create(outdir)}

	subtree_file = file.path(outdir, "sub.tre")
	timetree_file = file.path(outdir, "time.tre")
	cmd_file = file.path(outdir, "cmd")

	write.tree(tree, timetree_file)
	write.tree(t, subtree_file)
	#lapply(args, write, cmd_file, append=TRUE, ncolumns=1000)
}

