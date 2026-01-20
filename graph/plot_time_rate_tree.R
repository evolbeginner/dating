#! /mnt/hd1/home/sishuo/program/R/R-4.3.2/bin/Rscript


#################################################
library(ggtree)
library(ggplot2)
library(gridExtra)
library(scales)
library(phytools)  # For nodeHeights function
library(ape)


#################################################
get_rate_range <- function(rate_files) {
    all_rates <- numeric()
    for(file in rate_files) {
        tree <- read.tree(file)
        all_rates <- c(all_rates, tree$edge.length)
    }
    return(range(all_rates, na.rm = TRUE))
}


#################################################
args <- commandArgs(trailingOnly = TRUE)
is_log = FALSE
rate_range <- NULL

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
    } else if(args[i] == '--log'){
        is_log <- TRUE
        i <- i + 1
    } else if(args[i] == '--rate_range'){
        rate_range <- as.numeric(strsplit(args[i+1], ',')[[1]])
        rate_range <- exp(rate_range)
        i <- i + 2
    }
    else {
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
if (is.null(rate_range)){
    rate_range <- get_rate_range(ratetrees)
    rate_range[2] <- rate_range[2] * 1.2
}

if(is_log == TRUE){
    rate_range <- log(rate_range)
}

n_color_stops <- 9
rate_breaks <- seq(ifelse(0<=rate_range[1], 0, log(1e-5)), rate_range[2], length.out = n_color_stops)
rate_values <- rate_breaks


#################################################
extract_node_intervals <- function(tree, tree_df) {
    node_support <- lapply(seq_along(tree$node.label), function(i) {
        x <- tree$node.label[i]
        if (grepl("-", x)) {
            range_vals <- as.numeric(unlist(strsplit(x, "-")))
            node_id <- i + length(tree$tip.label)  # Ensure correct node mapping
            y_pos <- tree_df$y[node_id]  # Correct vertical position
            return(data.frame(node=node_id, 
                              min_age=max(tree_df$x) - range_vals[2], 
                              max_age=max(tree_df$x) - range_vals[1], 
                              y_position=y_pos))  
        }
        return(data.frame(node=NA, min_age=NA, max_age=NA, y_position=NA))
    })
    return(na.omit(do.call(rbind, node_support)))
}

#################################################
create_tree_plot <- function(time_file, rate_file) {
    time_tree <- read.tree(time_file)
    rate_tree <- read.tree(rate_file)
    if(is_log){
        rate_tree$edge.length <- log(rate_tree$edge.length)
    }

    tree_height <- max(phytools::nodeHeights(time_tree))
    max_label_length <- max(nchar(time_tree$tip.label))

    plot_data <- data.frame(
        node = time_tree$edge[,2],
        rate = rate_tree$edge.length
    )

    tree_df <- fortify(time_tree)  # Extract correct tree coordinates
    node_intervals <- extract_node_intervals(time_tree, tree_df)  # Get uncertainty info

    p <- ggtree(time_tree, size=1.2) %<+% plot_data + 
        geom_tree(aes(color=rate), size=1.5) +
        scale_color_gradientn(
            name = "Absolute substitution rate",
            #colors = colorRampPalette(c("#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c"))(100),  # More gradient steps
            colors = colorRampPalette(c("#2b83ba", "#4575b4", "#74add1", "#abd9e9", "#ffffbf", 
                            "#fee08b", "#fdae61", "#f46d43", "#d7191c", "#a50026"))(200),
            values = seq(0, 1, length.out = 100),  # Smooth interpolation
            #values = rate_values,
            limits = rate_range,
            breaks = pretty_breaks(n=6)(rate_range),  # More ticks for gradual shifts
            guide = guide_colorbar(
                direction = "vertical",
                barwidth = 1.5,
                barheight = 15,
                title.position = "top",
                title.hjust = 0.5,
                frame.colour = "black",
                ticks.colour = "black"
            )
        ) +
        geom_tiplab(size = 3, align = TRUE, hjust = 0, offset = 0.02 * tree_height) +
        geom_segment(data=node_intervals, 
                     aes(x=min_age, xend=max_age, y=y_position, yend=y_position),  
                     color="grey", size=1.2, alpha=0.5) +  # Corrected confidence intervals
        theme_tree2() +
        theme(
            legend.position = "right",
            legend.justification = "center",
            plot.title = element_text(size=10, hjust=0.5),
            legend.text = element_text(size=8),
            legend.title = element_text(size=9, face="bold"),
            legend.margin = margin(0, 20, 0, 0),
            plot.margin = unit(c(1, max_label_length*0.2, 1, 1), "cm")
        ) +
        xlim(-10, tree_height*2)

    return(p)
}

#################################################
plot_list <- list()
for(i in 1:length(timetrees)) {
    plot_list[[i]] <- create_tree_plot(timetrees[i], ratetrees[i])
}

# Simplified PDF dimensions
n_plots <- length(plot_list)
pdf_width <- ifelse(n_plots == 1, 14, 22)
pdf_height <- 10

# Output plots in a properly arranged format
pdf(output_file, width=pdf_width, height=pdf_height)
grid.arrange(
    grobs = plot_list,
    nrow = n_plots,  
    ncol = 1    
)
dev.off()

cat("Successfully created", n_plots, "tree plots in", output_file, "\n")
cat("Color scale range:", signif(rate_range[1],3), "to", signif(rate_range[2],3), "\n")

