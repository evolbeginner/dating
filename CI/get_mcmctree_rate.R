#! /bin/env Rscript


##############################################
library(phytools)
library(getopt)
library(coda)

args = commandArgs()
CURR_SCRIPT <- strsplit(args[grep('file=', args)], '=')[[1]][2]
DIR <- dirname(CURR_SCRIPT)

source(paste(c(DIR, '../sequential/lib/read_ont.R'), collapse='/'))
source(paste(c(DIR, '../sequential/lib/my_phylo.R'), collapse='/'))


##############################################
mcmctxt <- NULL
infile <- NULL
nrows <- -1
is_sort <- F
is_tip <- T
max_char_tip <- 100


##############################################
get_rnode_to_two_taxon_name <- function(node_to_two_taxon_name, add){
	rnode_to_two_taxon_name <- list()
	for(i in 1:length(node_to_two_taxon_name)){
		new_i <- paste('n', i+add, sep='')
		rnode_to_two_taxon_name[new_i] <- node_to_two_taxon_name[i]
	}
	rnode_to_two_taxon_name
}


get_mean_min_max_rates <- function(x){
	xs <- names(mcmc)[grepl(paste('^r_.*',x,sep=''), names(mcmc), perl=T)]
	quantile(unlist(mcmc[xs]), probs=c(0.5,0.025,0.975))
}


##############################################
spec <- matrix(
	c(
		'mcmctxt', 'm', 2, 'character',
		'infile', 'i', 2, 'character',
		'nrows', 'n', 2, 'integer',
		'max_char_tip', '', 2, 'integer',
		'sort', 's', 0, 'logical'
	), byrow=T, ncol=4
)

opt <- getopt(spec)

if(! is.null(opt$mcmctxt)){
	mcmctxt <- opt$mcmctxt
}
if(! is.null(opt$infile)){
	infile <- opt$infile
}
if(! is.null(opt$nrows)){
	nrows <- opt$nrows
}
if(! is.null(opt$max_char_tip)){
	max_char_tip <- opt$max_char_tip
}
if(! is.null(opt$sort)){
	is_sort <- T
}


##############################################
con <- file(infile, "r")
lines <- readLines(infile)
close(con)

SENTENCE <- 'Species tree for FigTree.'
numbered_tree_txt <- lines [ which(grepl(SENTENCE, lines)) + 1 ]
#numbered_tree_txt <- lines [ which(lines %in% SENTENCE) + 1]

n_tree <- ape::read.tree(text = numbered_tree_txt)
node_to_two_taxon_name <- get_node_to_two_taxon_name(n_tree, is_de_tip_no=T, is_sort=is_sort, is_tip=is_tip)


##############################################
add <- if(is_tip) 0 else length(n_tree$tip.label)
rnode_to_two_taxon_name <- get_rnode_to_two_taxon_name(node_to_two_taxon_name, add=add)

mcmc <- read.table(mcmctxt, nrows=nrows, header=T)
mcmc <- mcmc[1:nrow(mcmc)-1,]

# mean and min, max rates
rates <- lapply( names(rnode_to_two_taxon_name), get_mean_min_max_rates)

names(rates) <- rnode_to_two_taxon_name
#rates <- rates[!is.na(rates)] # remove NA from rates
rates <- rates[!sapply(rates, function(x){all(is.na(x))})]

cat(paste(c("node", "age", "min", "max"), collapse="\t"), "\n")
cat(paste(names(rates), sapply(rates, function(x){paste(x, collapse="\t")}), collapse="\n"), "\n")
#cat(paste(names(rates), rates, sep="\t", collapse="\n"), "\n")


