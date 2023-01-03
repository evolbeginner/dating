#! /bin/env Rscript


#############################################
library(getopt)
library(sn)
library(fitdistrplus)
library(parallel)


#############################################
is_norm <- F
is_gamma <- T
is_sn <- T
is_st <- T
cpu <- 4
is_reltime <- F

command = matrix(c( 
    'input', 'i', 2, 'character',
    'output', 'o', 2, 'character',
    'no_st', 's', 0, 'logical',
    'only_st', 'on', 0, 'logical',
    'cpu', 'n', 2, 'integer',
    'reltime', 'r', '0', 'logical',
    'type', 't', 2, 'character'),
    byrow=T, ncol=4
)
args=getopt(command)

print(args)


#############################################
input = args$input
type = args$type
if( !is.null(args$no_st) ){
	is_st <- F
}
if( !is.null(args$only_st) ){
	is_gamma <- F
	is_sn <- F
}
if( !is.null(args$only_norm) ){
	is_norm <- T
	is_gamma <- F
	is_sn <- F
	is_st <- F
}
if( !is.null(args$reltime) ){
	is_reltime <- T
}
if( !is.null(args$cpu) ){
	cpu <- args$cpu
}


#############################################
m <- read.table(input, header=T)
m <- m[, -1]
if(any(names(m) %in% c('lnL'))){
	m <- m[,-which(names(m) %in% c('lnL'))]
}


#############################################
fit_posterior_by_aic <- function(x){
	# x is the posterior samples
	mles <- list()
	params <- list()
	aics <- vector()

	# cauchy
	#mles$cauchy <- fitdist(x, 'cauchy')
	#params$cauchy <- mles$cauchy$estimate
	#aics['cauchy'] <- mles$cauchy$aic

	# norm
	if(is_norm){
		mles$norm <- fitdist(x, 'normal')
		params$norm <- mles$norm$estimate
		aics['norm'] <- mles$norm$aic
	}

	# gamma
	if(is_gamma){
		mles$gamma <- fitdist(x, 'gamma')
		params$gamma <- mles$gamma$estimate
		aics['gamma'] <- mles$gamma$aic
	}

	# sn
	if(is_sn){
		df <- 3
		mles$sn <- sn.mple(y=x, opt.method='Nelder-Mead')
		params$sn <- mles$sn$cp
		aics['sn'] <- -2 * mles$sn$logL + 2 * df
	}

	# st
	if(is_st){
		df <- 4
		mles$st <- st.mple(y=x, opt.method='Nelder-Mead')
		params$st <- mles$st$dp
		aics['st'] <- -2 * mles$st$logL + 2 * df
	}

	min <- min(aics)
	name <- names(params)[aics == min]
	if(is_reltime){
		if(reltime == 'unif'){
			
		}
	}

	if(name == 'norm' || name == 'normal'){
		paste('N(', paste(params$norm, collapse=","), ')' , sep='')
	}
	else if(name == "gamma"){
		paste('G(', paste(params$gamma, collapse=","), ')' , sep='')
	}else if(name == "sn"){
		paste('SN(', paste(params$sn, collapse=","), ')' , sep='')
	}else if(name == "st"){
		paste('ST(', paste(params$st, collapse=","), ')' , sep='')
	}
}

#res <- sapply(m, fit_posterior_by_aic)
res <- as.matrix(mclapply(m, fit_posterior_by_aic, mc.cores=cpu))


#############################################
if(is.null(args[["output"]])){
	write.table(res, col.names=T, sep="\t", quote=F)
} else{
	write.table(res, file=args$output, col.names=T, sep="\t", quote=F)
}


