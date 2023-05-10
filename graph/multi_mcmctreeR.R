#! /bin/env Rscript


############################################################
library(getopt)

library(MCMCtreeR, quietly = TRUE, warn.conflicts = FALSE)
data(MCMCtree.output)
attach(MCMCtree.output)


############################################################
read_figtree <- function(infile){
	figtree<-readMCMCtree(infile, from.file = T)
	figtree$nodeAges <- figtree$nodeAges * 100
	figtree$apePhy$edge.length <- figtree$apePhy$edge.length * 100
	figtree
}


############################################################
spec <- matrix(
	c('list', 'l', 2, 'character'),
	ncol=4, byrow=T
)

opt <- getopt(spec)
if(! is.null(opt$list)){
	#genes <- as.character(read.table(opt$list)$V1)
	genes <- read.table(opt$list)
	rownames(genes) <- genes$V1
}


############################################################
figtree_files <- c(
	"~/project//BTL/results/dating/official/wCelegans-correct/bootstrap/1-pf/dating//C60/mcmctree/rrtc/official-mcmc987/marginal/FigTree.tre",
	"~/project//BTL/results/dating/official/wCelegans-correct/bootstrap/2-pf/dating//C60/mcmctree/rrtc/official-mcmc987/marginal/FigTree.tre",
	"~/project/BTL/results/dating/official/wCelegans-correct/date-alt/1-pf/Calibs/EUK/rafa/mcmctree/rrtc/official-mcmc987//marginal/FigTree.tre",
	"~/project/BTL/results/dating/official/wCelegans-correct/date-alt/1-pf/Calibs/BAC/woCyano/mcmctree/rrtc/official-mcmc987//marginal/FigTree.tre",
	"~/project/BTL/results/dating/official/wCelegans-correct/date-alt.topo/rick-mito/1-pf/dating/C60/mcmctree/rrtc/official-mcmc987/marginal/FigTree.tre",
	"~/project/BTL/results/dating/official/wCelegans-correct/date-fg/1-pf/dating/C60/mcmctree/rrtc/official-mcmc987/marginal/FigTree.tre",
	"~/project//BTL/results/dating/expanded/results/date/LG.ft/bootstrap/dating/C60/mcmctree/rrtc/official-mcmc987.expanded/joint/FigTree.tre",
	"~/project//BTL/results/dating/2nd/DATE/date3/1-pf/dating/C60/mcmctree/rrtc/official-mcmc987/marginal/FigTree.tre"
	#"~/project//BTL/results/dating/expanded/results/date/LG.ft/bootstrap/dating/C60/mcmctree/rrtc/official-mcmc987.expanded/marginal/FigTree.tre"
)


############################################################
WIDTH <- 10
HEIGHT <- 30


############################################################
pdf("haha.pdf", height=HEIGHT)
nrow <- ceiling(length(figtree_files)/2)
ncol <- 2
par(mfrow = c(nrow,2), mai=rep(0.01,4))

figtrees <- lapply(figtree_files, read_figtree)
max_times <- sapply(figtrees, function(x){max( x$nodeAges[,1] )})
widths <- max_times/(max(max_times)) * WIDTH / ncol * 0.5

get_my_col <- function(t, genes){
	stopifnot( length(genes)>=1 )
	#x <- rep(0, each=length(t$tip.label))
	ncol <- 1
	x <- matrix(rep(0,length(t$tip.label)*ncol), ncol=ncol)
	rownames(x) <- t$tip.label
	colnames(x) <- letters[1:ncol]
	#x[ t$tip.label %in% genes, 1 ] <- 1
	overlap <- rownames(x)[ rownames(x) %in% genes$V1 ]
	x[ rownames(x) %in% genes$V1 ] <- genes[overlap,]$V2
	#x[ ! t$tip.label %in% genes, 2 ] <- 100
	x
}

for(i in 1:length(figtrees)){
	figtree <- figtrees[[i]]
	#if(! i %in% c(1,8)){next}
	max_time <- max(figtree$nodeAges[,1])
	print(max_time/(max(max_times)))
	par(pin=c(widths[i], HEIGHT/nrow))
	my_col <- get_my_col(figtree$apePhy, genes)
	head(my_col)
	MCMC.tree.plot( figtree, scale.res = c("Eon"), cex.tips = 0.2, show.tip.label=T, node.method='none')
	#phydataplot( my_col, figtree$apePhy, 'm', continuous=F, offset=-100, funcol = colorRampPalette(c("white", "red")), legend='none')
	phydataplot( my_col, figtree$apePhy, 'm', continuous=F, funcol = colorRampPalette(c("white", "red", "blue")), legend='none')
}

dev.off()


