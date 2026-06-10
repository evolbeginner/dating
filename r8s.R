#! /bin/env Rscript

library(ape)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop("Usage: chronos_tree.R <input_tree.nwk> <output_tree.nwk>")
}

t <- read.tree(args[1])

timetree <- chronos(t)

write.tree(timetree, file = args[2])

