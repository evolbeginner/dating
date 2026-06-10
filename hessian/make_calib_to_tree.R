#! /usr/bin/env Rscript

suppressWarnings({
    library(getopt)
    library(ape)
})

get_calib_interval <- function(x, percent = 0.2, sp = 0) {
  bottom <- round(x * (1 - percent + sp), 5)
  top    <- round(x * (1 + percent + sp), 5)
  return(c(bottom, top))
}

treefile      <- NULL
outfile       <- NULL
percent       <- 0.2
shift_percent <- 0
num           <- 2
is_only_min   <- F
is_only_max   <- F
is_ancient    <- F   # calibrate top-ancient non-root nodes, while keeping root

command = matrix(
  c(
    'tree',      't', 2, 'character',
    'outfile',   'o', 2, 'character',
    'num',       'n', 2, 'integer',
    'only_min',  'm', 0, 'logical',
    'only_max',  'M', 0, 'logical',
    'shift',     's', 2, 'double',
    'percent',   'p', 2, 'double',
    'ancient',   'a', 0, 'logical'
  ),
  byrow = TRUE, ncol = 4
)
args = getopt(command)

if (!is.null(args$tree)) {
  treefile <- args$tree
}
if (!is.null(args$outfile)) {
  outfile <- args$outfile
}
if (!is.null(args$num)) {
  num <- args$num
}
if (!is.null(args$only_min)) {
  is_only_min <- T
}
if (!is.null(args$only_max)) {
  is_only_max <- T
}
if (!is.null(args$shift)) {
  shift_percent <- args$shift
}
if (!is.null(args$percent)) {
  percent <- args$percent
}
if (!is.null(args$ancient)) {
  is_ancient <- T
}

tree <- ape::read.tree(treefile)

root_no <- length(tree$tip.label) + 1

d <- dist.nodes(tree)[root_no, 1] -
      dist.nodes(tree)[root_no, (root_no):(root_no + tree$Nnode - 1)]

d_order <- order(d)
root_idx <- which.max(d)

tree$node.label <- rep("NA", tree$Nnode)

if (is_ancient) {
  # Top-ancient nodes excluding root, but root is still calibrated
  d_desc <- rev(d_order)
  d_desc <- d_desc[d_desc != root_idx]
  k <- min(num, length(d_desc))
  nodes <- unique(c(d_desc[1:k], root_idx))
} else {
  # legacy behavior: quantile-based nodes + root
  nodes <- sapply(1:num, function(x) {
    floor(x / (num + 1) * length(d))
  })
  nodes <- d_order[nodes]
  nodes <- unique(c(nodes, root_idx))
}

ages_root <- get_calib_interval(d[root_idx], percent, shift_percent)
max_age <- ages_root[2]

for (i in nodes) {
  age  <- d[i]
  ages <- get_calib_interval(age, percent, shift_percent)

  if (is_only_min) {
    if (i == root_idx) {
      tree$node.label[i] <- paste(">", ages[1], "<", ages[2], sep = "")
    } else {
      #tree$node.label[i] <- paste(">", ages[1], "<", max_age, sep = "")
      tree$node.label[i] <- paste(">", ages[1], sep = "")
    }
  } else if (is_only_max) {
    tree$node.label[i] <- paste("<", ages[2], sep = "")
  } else {
    tree$node.label[i] <- paste(">", ages[1], "<", ages[2], sep = "")
  }
}

a <- write.tree(tree)
a <- gsub("\\)NA", ")", a)

if (is.null(outfile)) {
  cat(a, "\n")
} else {
  writeLines(a, con = outfile)
}
