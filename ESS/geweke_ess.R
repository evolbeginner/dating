#! /bin/env Rscript


#########################################################
suppressWarnings(suppressMessages(library(ergm)))

library(coda)
library(ergm)
library(parallel)
library(GetoptLong)


#########################################################
get_mcmc_obj <- function(infile){
	t <- read.table(infile, header=TRUE, nrows=n)
	t <- t[, -which(colnames(t) %in% c('Gen'))]
	m <- mcmc(t)
}


#########################################################
infiles <- vector()
ess <- F
autocorrel <- F
geweke <- F
gelman <- F

n = 1000000 # max no. of rows to read


#########################################################
GetoptLong(
	"infile=s@", "infiles",
	"ess!", "calculate ESS",
	"autocorrel!", "check auto correlation",
	"geweke!", "calculate Geweke's diagnostic",
	"gelman!", "Gelman and Rubin's convergence diagnostic",
	"verbose",  "Print message."
)

infiles <- infile


#########################################################
m <- mcmc(read.table(infiles[1], header=TRUE, nrows=n))

mcmcs <- mclapply(infiles, get_mcmc_obj, mc.cores=4)
c = mcmc.list(mcmcs)


#########################################################
# ESS
if(ess){
	cat("ESS ......","\n")
	ess=coda::effectiveSize(c); print(ess) # c or a
	cat("\n")
}


#########################################################
# autocorrelation
if(autocorrel){
	cat("Auto-correlation ......","\n")
	autocorr.diag(c, lags = c(0, 10, 50, 100, 500), relative=TRUE)
	cat("\n")
}


#########################################################
# geweke
if(geweke){
	cat("Geweke ......", "\n")
	pvalues <- pnorm(geweke.diag(c)[[1]]$z)
	print(pvalues)
	#geweke.diag(c)$z
	cat("\n")

	cat("Multivariate Geweke", "\n")
	mv_geweke <- geweke.diag.mv(c, split.mcmc.list = T)
	for(i in 1:length(mv_geweke)){ cat(unname(mv_geweke[[i]]$p.value),"\n") }
}


#########################################################
# heidel
#heidel.diag(c[[1]])


#########################################################
# gelman
if(gelman){
	cat("Gelman ......", "\n")
	if(length(c) >= 2){
		print(gelman.diag(c, autoburnin=F))
		cat("\n")
	} else{
		print("For Gelman, at least 2 chains have to be provided! Skipping ......")
	}
}


