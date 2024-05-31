#! /usr/bin/env Rscript


######################################################################
library(getopt)
library(tidyverse)


######################################################################
ordered_cat <- NA
ordered_class <- NA


######################################################################
spec = matrix(
	c(
		'infile', 'i', 1, 'character',
		'outfile', 'o', 1, 'character',
		'minmax', 'm', 1, 'character',
		'color', 'c', 1, 'character',
		'ordered_cat', 'z', 1, 'character',
		'ordered_class', 'x', 1, 'character',
		'pointrange', 'p', 0, 'logical'
	),
	byrow=T, ncol=4
)

opts <- getopt(spec)

infile <- opts$infile
outfile <- opts$outfile
minmax <- as.numeric(unlist(strsplit(opts$minmax, ',')))
color <- opts$color
ordered_cat_file <- opts$ordered_cat
ordered_class_file <- opts$ordered_class

if(!is.null(ordered_cat_file)){ordered_cat <- unlist(read.table(ordered_cat_file))}
if(!is.null(ordered_class_file)){ordered_cat <- unlist(read.table(ordered_class_file))}

if(!is.null(opts$pointrange)){
	bar_graph_func <- geom_pointrange
}else{
	bar_graph_func <- geom_errorbar
}

if (is.null(infile) | is.null(outfile)){
	print("infile or outfile not given! Exiting ......"); q()
}


######################################################################
#Make up data
df<-read.table(infile, header=TRUE)

df <- df %>%
	group_by(class, cat)

head(df)


######################################################################
#The plot
#ordered_cat = c("Topo1", "Topo2", "Topo3", "Topo4", "Topo5", "Topo6", "Topo7", "Topo8", "Topo9", "Topo10", "Topo11", "Topo12")
#ordered_class = c("Mitochondria", "Caulobacterales", "Holosporales", "Pelagibacterales", "Rhizobiales", "Rhodobacterales", "Rhodospirillales", "Rickettsiales", "Sphingomonadales")
#ordered_class = c("Mitochondria", "Rickettsiales", "Sphingomonadales", "Caulobacterales", "Rhizobiales", "Rhodobacterales", "Rhodospirillales", "Pelagibacterales", "Holosporales")


if(F){
cmd1 <- ifelse(!missing(ordered_class) && !missing(ordered_cat), 
	ggplot(df, aes(factor(class,levels=ordered_class), mean, col=factor(cat,levels=ordered_cat))) + geom_point(position = position_dodge(width = 0.8), size=1.5), 
	ggplot(df, aes(factor(class), mean, col=factor(cat))) + geom_point(position = position_dodge(width = 0.8), size=1.5)
	)
}


######################################################################
	#ggplot(df, aes(factor(class,levels=ordered_class), mean, col=factor(cat,levels=ordered_cat))) + geom_point(position = position_dodge(width = 0.8), size=1.5), 
	ggplot(df, aes(factor(class), mean, col=factor(cat))) + geom_point(position = position_dodge(width = 0.8), size=1.5) +
	bar_graph_func(aes(class,ymin=min,ymax=max), position = position_dodge(width = 0.8), width=0.8, size=0.8) +
	xlab(NULL) + ylab("95% HPD interval (Ma)") + theme_bw() +
	theme(axis.text.x = element_text(size=16, angle = 15), legend.title = element_blank()) + coord_cartesian(ylim = c(minmax[1], minmax[2]))


ggsave(outfile, width = 16, height = 5)
dev.off()


