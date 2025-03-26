#! /usr/bin/env Rscript


#####################################################
suppressWarnings({
    library(ape)
})


#####################################################
is_branch <- F

args <- commandArgs(TRUE)


#####################################################
t1 <- ape::read.tree(args[1])
t2 <- ape::read.tree(args[2])
titles <- args[3:4]
if(args[5] == "TRUE" || args[5] == "T" || args[5] == 'branch'){
    is_branch <- T
}

root_no <- length(t1$tip.label) + 1

if (!is_branch){
    d1 <- dist.nodes(t1)[root_no, 1] - dist.nodes(t1)[root_no, (root_no):(root_no+t1$Nnode-1)]
    d2 <- dist.nodes(t2)[root_no, 1] - dist.nodes(t2)[root_no, (root_no):(root_no+t2$Nnode-1)]
} else{
    d1 <- t1$edge.length
    d2 <- t2$edge.length
}

bs1 <- sapply(t1$node.label, function(x){ a=as.numeric(strsplit(x,"-")[[1]]); a[2]-a[1] })
bs2 <- sapply(t2$node.label, function(x){ a=as.numeric(strsplit(x,"-")[[1]]); a[2]-a[1] })
#d1 <- bs1/d1
#d2 <- bs2/d2
#print(mean(d1))
#print(mean(d2))

c <- abs(d1-d2)
max <- max(c(d1,d2))
#print((c/max)[which(c/max>0.04)])

a <- d1 - d2
max_bls <- apply(matrix(c(d1, d2), ncol=2), 1, max)
#order = rev(order(abs(a)/max_bls))
#print(d1[order])

score <- sum(a^2)^0.5

mean_rel_diff <- mean(abs(a)/max_bls)

#cor_ <- cor(t1$edge.length, t2$edge.length)

lm_ <- lm(d2 ~ d1+0)

#print(round(c(score, mean_rel_diff, unname(lm_$coefficients), summary(lm_)$r.squared), 3)) # the single coefficient is the slope
cat(round(c(score, mean_rel_diff, unname(lm_$coefficients), summary(lm_)$r.squared), 3), sep="\t", "\n") # the single coefficient is the slope

lim <- max(d1, d2) * 1.1

plot(d1, d2, xlab="", ylab="", xlim=c(0,lim), ylim=c(0,lim))
abline(0,1,col="darkgrey", lty=2, lwd=2)
if (! is.null(titles)){
	title(xlab = titles[1], ylab = titles[2])
}

