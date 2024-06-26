#! /bin/env Rscript


#####################################################
library(GetoptLong)
library(parallel)
library(ape)
suppressMessages(library(sn))

args = commandArgs()

CURR_SCRIPT <- strsplit(args[grep('file=', args)], '=')[[1]][2]
DIR <- dirname(CURR_SCRIPT)
source(paste(c(DIR, 'lib/my_phylo.R'), collapse='/'))
source(paste(c(DIR, 'lib/read_ont.R'), collapse='/'))


#####################################################
find_lca <- function(two_taxon_str, t){
	tips <- unlist(strsplit(two_taxon_str, '[|]')) # a vector of two tips
	#print(c(t, tips))
	node <- getMRCA(t, tips)
	paste(c('t_n', node), collapse='')
}


plot_fit <- function(x, show_param=F){
	node <- x[[1]]
	param <- x[[2]]
	params.ori <- unlist(strsplit(param, ','))
	distr_abbr <- unlist(strsplit(param, '\\('))[1]
	params <- unlist( lapply(params.ori, function(x){ y1 <- sub('[A-Z]+[(]', '', x); sub('[)]', '', y1) } ) )
	params <- round(as.numeric(params),3)
	if( grepl(pattern="^G", x=param) ){
		curve(dgamma(x, params[1], params[2]), col=color$fit, add=T)
	}else if( grepl(pattern="^SN", x=param) ){
		curve(dsn(x, params[1], params[2], params[3]), col=color$fit, add=T)
	}else if( grepl(pattern="^ST", x=param) ){
		curve(dst(x, params[1], params[2], params[3], params[4]), col=color$fit, add=T)
	}else if( grepl(pattern='^B', x=param) ){
		curve(dunif(x, params[1], params[2]), col=color$fit, add=T)
	}

	if(show_param){
		param.to_show <- paste(distr_abbr, '(', paste(params[1:length(params)],collapse=','), ')', sep='')
		title(param.to_show, line=-0.4, cex.main=0.5)
	}
}



#####################################################
t_n <- F
cpu <- 4
n <- -1
nrnc <- '1,1'
fit <- NULL
xmax <- 20
is_de_tip_no <- T
no_de_tip_no <- F
show_param <- F

fit_df <- NULL
color <- data.frame('fit'='purple', 'first'='blue', 'second'='red', stringsAsFactors=FALSE)
is_perform_plot_second <- T


#####################################################
GetoptLong(
    "tree2", "sequential second step tree",
    "trees=s@", "sequential trees",
    "mcmctxts=s@", "sequential first step mcmc.txt",
    "nrnc=s", "# of iterations in mcmc.txt to read",
    "cpu=i", "n_cores used used in reading mcmc.txt by mclapply",
    "n=i", "# of iterations in mcmc.txt to read",
    "t_n!", "add t_n to each internal node name?",
    "fit=s", "fit file (.tbl) generated by fit_mcmctree_posterior.R",
    "xmax=i", "xmax",
    "no_de_tip_no!", "to de tip number (eg: 6_Homo_sapiens to Homo_sapiens)",
    "show_param!", "to show the params of the fitted distr in each plot",
    "verbose!", "Print message."
)


#####################################################
if(! is.null(nrnc)){
	a <- as.numeric(unlist(strsplit(nrnc, ',')))
	nrow_plot <- a[1]
	ncol_plot <- a[2]
}

if(! is.null(fit)){
	fit_file <- fit
	fit_df <- read.table(fit_file, header=F, stringsAsFactors=F)
}

if(mcmctxts[1] == mcmctxts[2]){
	is_perform_plot_second <- F
}

if(no_de_tip_no){
	is_de_tip_no <- F
}


#####################################################
# read mcmc.txt
mcmcs <- mclapply(mcmctxts, get_mcmc_obj, n=n, mc.cores=cpu)


#####################################################
#is_read_tree_ok <- try(ts <- lapply(trees, read.tree))
#if(! is_read_tree_ok){
ts <- lapply(trees, read_ont)
if(is_de_tip_no){
	ts <- lapply(ts, de_tip_no_for_tree)
}

# get node_labels (list) for all intrees
node_labels <- lapply(ts, function(t){t$node.label}) # node_labels: list, each element being vec
if(t_n){ node_labels <- lapply(node_labels, function(labels){paste('t_n', labels, sep='')}) }

# get node2taxa (list) for all intrees
node2taxa <- lapply(ts, get_node_to_two_taxon_name, is_de_tip_no) # de_tip_no: 6_Homo_sapiens to Homo_sapiens

# find the corresponding internal nodes in the second tree, given the tip names of the first tree
if(F){
	associate_taxa_btwn_trees
}

sec_nodes <- unlist(lapply(node2taxa[[1]], find_lca, ts[[2]]))

# rela:	nodes1 -> taxa1 -> nodes2
df <- data.frame(nodes1=node_labels[[1]], taxa1=node2taxa[[1]], nodes2=sec_nodes, stringsAsFactors=F)


#####################################################
n_nodes <- length(df$nodes1)

par(mfrow=c(nrow_plot, ncol_plot), mai=rep(0.3,4))


for(i in 1:n_nodes){
	node1 <- df$nodes1[i]
	node2 <- df$nodes2[i]
	#cat(i, node1, node2, fill=T)

	li <- list(mcmcs[[1]][,node1], mcmcs[[2]][,node2])
	max_den <- max(as.numeric( lapply( li, function(i){max(density(i)$y)} )))
	ymax = max_den * 1.2

	plot(density(mcmcs[[1]][,node1]), col=color$first, main=node1, yaxt='n', xlab='', ylab='', ylim=c(0,ymax), xlim=c(0,xmax), line=0.5, cex.main=0.8)

	if(is_perform_plot_second){
		lines(density(mcmcs[[2]][,node2]), col=color$second)
	}

	if(! is.null(fit_df)){
		row <- fit_df[,1] == node1
		if(row == T){
			plot_fit(as.list(fit_df[row, ]), show_param)
		}
	}
}


