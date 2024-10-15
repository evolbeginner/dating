library(mcmc3r)

clk <- mcmc3r::stepping.stones()

#cat(clk$logml)
cat(paste(c(clk$logml,clk$se), "\t"))
cat("\n")
