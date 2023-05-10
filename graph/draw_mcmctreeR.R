#! /bin/env Rscript


###################################################
library(getopt)
library(MCMCtreeR)


###################################################
MCMCtree.posterior <- NA
figtree <- NA
plottype <- "distributions"
outfile <- NA
nrow <- -1
is_nodelabel <- F


###################################################
spec = matrix(
	c(
		'mcmctxt', 'm', 2, 'character',
		'figtree', 'f', 2, 'character',
		'plottype', 'p', 2, 'character',
		'outfile', 'o', 2, 'character',
		'nrow', 'n', 2, 'numeric',
		'nodelabel', '', 0, 'logical'
	), byrow=T, ncol=4
)

opts = getopt(spec)


###################################################
if(! is.null(opts$figtree)){
	figtree <- opts$figtree
}
if(! is.null(opts$mcmctxt)){
	mcmctxt <- opts$mcmctxt
}
if(! is.null(opts$plottype)){
	plottype <- opts$plottype
}
if(! is.null(opts$outfile)){
	outfile <- opts$outfile
}
if(! is.null(opts$nrow)){
	nrow <- opts$nrow
}
if(! is.null(opts$nodelabel)){
	is_nodelabel <- T
}


###################################################
phy <- readMCMCtree(figtree, from.file = T)

if(!is.null(mcmctxt)){
	MCMCtree.posterior <- read.table(mcmctxt, header=T, nrows=nrow)
}

pdf(outfile)

MCMC.tree.plot(phy, MCMC.chain = MCMCtree.posterior, cex.tips = 0.6, time.correction = 100, plot.type = plottype, cex.age = 1, cex.labels = 1, relative.height = 0.08, col.tree = "grey40", scale.res = c("Eon"), no.margin = TRUE, label.offset = 0, density.col = "pink", density.border.col = "#00000080", col.age = "#008b0080")

if(is_nodelabel){
	nodelabels(bg='lightblue', adj=c(0.1,1))
}

dev.off()


