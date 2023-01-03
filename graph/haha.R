#! /usr/bin/env Rscript


######################################################################
library("ggplot2")
library(ggrepel)


######################################################################
#Make up data
age<-read.table("1.list")$V1
bpf<-read.table("2.list")$V1
agesd<-read.table("1.list")$V2
bpfsd<-read.table("2.list")$V2 
pop.size<-runif(5,5,50)

df <- data.frame(
  age = age,
  bpf = bpf,
  agesd = agesd,
  bpfsd = bpfsd
)


######################################################################
#The plot
pdf("haha.pdf")

p <- ggplot(df, aes(age, bpf))

labels = gsub("(0|1|2|3|4|5|6|7|8|[.])*", "", df$age)

p + geom_point() + geom_errorbarh(aes(xmax=age+agesd/2, xmin=age-agesd/2), color="blue") + geom_errorbar(aes(ymax=bpf+bpfsd/2,ymin=bpf-bpfsd/2), color="blue") +
	geom_text_repel(aes(label = labels,  color = "red"), size = 3) +
	theme_classic()

dev.off()

