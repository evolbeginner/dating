#! /bin/env Rscript

#################################################
library(ape)
library(ggtree)
library(ggplot2)
library(gridExtra)
library(scales)

#################################################

args <- commandArgs(trailingOnly = TRUE)

timetrees <- c()
ratetrees <- c()
output_file <- "output.pdf"

i <- 1
while(i <= length(args)) {
    if(args[i] == "-t") {
        timetrees <- c(timetrees, args[i+1])
        i <- i + 2
    } else if(args[i] == "-r") {
        ratetrees <- c(ratetrees, args[i+1])
        i <- i + 2
    } else if(args[i] == "-o") {
        output_file <- args[i+1]
        i <- i + 2
    } else {
        i <- i + 1
    }
}

if(length(timetrees) != length(ratetrees)) {
    stop("Error: Number of time trees (-t) must match number of rate trees (-r)")
}

if(length(timetrees) < 1) {
    stop("Usage: Rscript script.R -t timetree1 -r ratetree1 [-t timetree2 -r ratetree2] [-o output.pdf]")
}

#################################################
get_rate_range <- function(rate_files) {
    all_rates <- numeric()
    for(file in rate_files) {
        tree <- read.tree(file)
        all_rates <- c(all_rates, tree$edge.length)
    }
    return(range(all_rates, na.rm = TRUE))
}

rate_range <- get_rate_range(ratetrees)
rate_range[2] <- rate_range[2] * 1.3
n_color_stops <- 9 # Number of color transitions
rate_breaks <- seq(0, rate_range[2], length.out = n_color_stops)
rate_values <- rate_breaks

#################################################
create_tree_plot <- function(time_file, rate_file, plot_title) {
    time_tree <- read.tree(time_file)
    rate_tree <- read.tree(rate_file)

    plot_data <- data.frame(
        node = time_tree$edge[,2],
        rate = rate_tree$edge.length
    )

    p <- ggtree(time_tree, size=1.2) %<+% plot_data +
        geom_tree(aes(color=rate), size=1.5) +
        scale_color_gradientn(
            name = "Evolutionary Rate",
            colors = c("#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c",
                      "#a50026", "#800026", "#400026", "#000000"),
            values = rate_values,
            limits = rate_range,
            breaks = pretty_breaks(n=6)(rate_range),
            guide = guide_colorbar(
                direction = "vertical", # Vertical color bar
                barwidth = 1.5,
                barheight = 15,
                title.position = "top",
                title.hjust = 0.5,
                frame.colour = "black",
                ticks.colour = "black"
            )
        ) +
        geom_tiplab(size=4, align=TRUE) +  # Changed from 2.5 to 4 for bigger tip labels
        geom_label(
            aes(label=round(rate, 3)),
            size=2,
            alpha=0.7,
            label.padding = unit(0.1, "lines"),
            color = "black"
        ) +
        theme_tree2() +
        ggtitle(plot_title) +
        theme(
            legend.position = "right",
            legend.justification = "center",
            plot.title = element_text(size=10, hjust=0.5),
            legend.text = element_text(size=8),
            legend.title = element_text(size=9, face="bold"),
            legend.margin = margin(0, 20, 0, 0)
        )

    return(p)
}

#################################################
plot_list <- list()
for(i in 1:length(timetrees)) {
    plot_title <- paste("Tree Pair", i, "\n",
                       "Time: ", basename(timetrees[i]), "\n",
                       "Rate: ", basename(ratetrees[i]))

    plot_list[[i]] <- create_tree_plot(timetrees[i], ratetrees[i], plot_title)
}

n_plots <- length(plot_list)
pdf_width <- ifelse(n_plots == 1, 12, 20)  # Increased from 10/16 to 12/20
pdf_height <- ifelse(n_plots == 1, 9, 9)   # Increased from 8 to 9

pdf(output_file, width=pdf_width, height=pdf_height)
grid.arrange(
    grobs = plot_list,
    ncol = min(2, n_plots),
    widths = if(n_plots == 1) 1 else c(0.9, 1)
)
dev.off()

cat("Successfully created", n_plots, "tree plots in", output_file, "\n")
cat("Color scale range:", signif(rate_range[1],3), "to", signif(rate_range[2],3), "\n")
