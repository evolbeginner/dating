#! /usr/bin/env Rscript

# old_name: generate_multiplot.R


################################################
library(ggtree)


################################################
t1=read.tree("phan.tre"); t2=read.tree("moss-Ban.tre"); t3=read.tree("root10.tre"); t4=read.tree("partition.single.list.tre"); t5=read.tree("IR.tre"); t=read.tree("AR.tre")

################################################
p1=ggtree(t1); p2=ggtree(t2); p3=ggtree(t3); p4=ggtree(t4); p5=ggtree(t5); p=ggtree(t)

p1 = p1 + geom_cladelabel(node=91, label="non-Rickettsiales Alphaproteobacteria", align=T, color='blue') + geom_cladelabel(node=142, label="Rickettsiales", align=T, color='red') + geom_cladelabel(node=153, label="Eukaryotes", align=T, color='orange')
p2 = p2 + geom_cladelabel(node=91, label="non-Rickettsiales Alphaproteobacteria", align=T, color='blue') + geom_cladelabel(node=142, label="Rickettsiales", align=T, color='red') + geom_cladelabel(node=153, label="Eukaryotes", align=T, color='orange')
p3 = p3 + geom_cladelabel(node=91, label="non-Rickettsiales Alphaproteobacteria", align=T, color='blue') + geom_cladelabel(node=142, label="Rickettsiales", align=T, color='red') + geom_cladelabel(node=153, label="Eukaryotes", align=T, color='orange')
p4 = p4 + geom_cladelabel(node=91, label="non-Rickettsiales Alphaproteobacteria", align=T, color='blue') + geom_cladelabel(node=142, label="Rickettsiales", align=T, color='red') + geom_cladelabel(node=153, label="Eukaryotes", align=T, color='orange')
p5 = p5 + geom_cladelabel(node=91, label="non-Rickettsiales Alphaproteobacteria", align=T, color='blue') + geom_cladelabel(node=142, label="Rickettsiales", align=T, color='red') + geom_cladelabel(node=153, label="Eukaryotes", align=T, color='orange')
p = p + geom_cladelabel(node=91, label="non-Rickettsiales Alphaproteobacteria", align=T, color='blue') + geom_cladelabel(node=142, label="Rickettsiales", align=T, color='red') + geom_cladelabel(node=153, label="Eukaryotes", align=T, color='orange')

pdf("1.pdf")
multiplot(p1,p2,p3,p4,p5,p,ncol=1)
dev.off()

