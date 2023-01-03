#! /bin/env Rscript


#############################################
library(getopt)
library(ape)


#############################################
measure <- 'SSE'


#############################################
command=matrix(c( 
    'tree', 't', 2, 'character',
    'outgroup', 'o', 2, 'character',
    'root_time', 'r', 2, 'double',
    'measure', 'm', 2, 'character'
),
    byrow=T, ncol=4
)

args=getopt(command)

if(! is.null(args[["tree"]])){
	t.rt <- read.tree(args$tree)
}

if(! is.null(args[['outgroup']])){
	out.tip <- as.vector(unlist(read.table(args$outgroup)))
}

if(! is.null(args[['root_time']])){
	root.time <- args$root_time
}

if(! is.null(args[['measure']])){
	measure <- args$measure
}


#############################################
source("~/software/phylo/ddBD/code/ddBD.R")


#############################################
#t.rt = read.tree("data/substitution.tree")

#out.tip = c("Geopsychrobacter_electrodiphilus_DSM_16401", "Desulfocapsa_sulfexigens_DSM_10523", "Desulfobacca_acetoxidans_DSM_11109", "Desulfotignum_phosphitoxidans_DSM_1368", "Chondromyces_apiculatus_DSM_436")

ddBD(t.rt, out.tip, root.time = root.time, measure = measure) # SSE or KL

