library(simclock)
library(ape)

r=0.025; reltt <- relaxed.tree(tt, model="gbm", r=r, s2=.5); var(reltt$edge.length); log(r)
