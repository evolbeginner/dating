library(mcmc3r); b = mcmc3r::make.beta(n=8, a=5, method="step-stones"); mcmc3r::make.bfctlf(b, ctlf="mcmctree.ctl", betaf="beta.txt")

# library(mcmc3r); clk <- mcmc3r::stepping.stones(); clk$logml;
