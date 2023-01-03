#! /usr/bin/env Rscript


###################################################
library(ggtree)


###################################################
args=commandArgs(T)

infile = args[1]

tree = read.tree(infile)

pdf("node_no.pdf")
ggtree(tree) + geom_text2(aes(subset=!isTip, label=node), hjust=-.3) + geom_tiplab()
dev.off()


