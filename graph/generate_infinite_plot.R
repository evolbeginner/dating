#! /usr/bin/env Rscript


#####################################################
library(ggplot2)
library(getopt)
#library(cowplot)
#library(gridExtra)


#####################################################
add_interval_col_to_df <- function(df){
	if(any(grepl('min', names(df)))){
		df$interval <- df$max - df$min
	}
	df
}


#####################################################
spec = matrix(
	c(
		'infile', 'i', 1, 'character',
		'outfile', 'o', 1, 'character',
		'minmax', 'm', 1, 'character'
	),
	byrow=2, ncol=4
)

opts = getopt(spec)
infile = opts$infile
outfile = opts$outfile
minmax = as.numeric(unlist(strsplit(opts$minmax, ',')))


#####################################################
df <- read.table(infile, header=TRUE)

df <- add_interval_col_to_df(df)

df.lm <- lm(interval ~ age+0, data = df)

cat("R^2: ", summary(lm(interval~age+0, data = df))$r.squared)
cat("\n")
cat("slope: ", df.lm$coefficients)
cat("\n")


lm.scatter <- ggplot(df, aes(x=age, y=interval)) + 
  geom_point(color='black', size = 2) + xlim(minmax) + ylim(minmax) + 
  geom_abline(color="grey", intercept=0, slope=df.lm$coefficients[1], size=1)

p = lm.scatter

#p <- with(a,plot(age, interval)) + abline(0, df.lm$coefficients[1])
p <- p + theme_set(theme_bw()) + theme_set(theme_bw()) + theme(panel.grid.minor=element_line(colour=NA))

p <- p + xlab("Posterior mean age (Ma)") + ylab("95% HPD width (Ma)")

p <- p + theme(text = element_text(size=24), legend.title = element_blank())

if (! is.null(outfile)){
	ggsave(outfile, p)
}
q()

