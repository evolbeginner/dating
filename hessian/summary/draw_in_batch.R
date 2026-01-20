#! /bin/env Rscript


suppressPackageStartupMessages({
    library(GetoptLong)
    library(ggplot2)
    library(cowplot)
    library(dplyr)
    library(tidyr)
    library(ggpubr)
    library(ggbeeswarm)
    library(scales)
    }
)


#############################################
# Helper function to merge data columns into a long format
r_merge_list <- function(d, y='score'){
    m <- as.matrix(d)
    r = matrix()
    for(i in 1:ncol(m)){r <- rbind(r, as.matrix(m[,i]))}
    r <- as.matrix(r[-1])
    d <- data.frame(r, y=as.character(rep(1:ncol(m), each=nrow(m))))
    names(d) <- c(y, 'model')
    d
}

# Helper function to determine y-axis limits
determine_yminmax <- function(df, ymin, ymax){
    sorted_score <- sort(df$score)
    if(is.null(ymin)){
        ind <- ceiling(0.05 * length(sorted_score))
        ymin <- sort(sorted_score)[ind]
    }
    if(is.null(ymax)){
        ind <- ceiling(0.95 * length(sorted_score))
        ymax <- max(sort(df$score))
    }
    return(c(ymin, ymax))
}


#############################################
# Default parameters
infiles = NULL
y <- NULL
ymin <- 0
ymax <- NULL
outlier_shape <- 19 # change to NA if no outlier is wanted
categories <- NULL
mu <- FALSE
by <- 'model'
color <- FALSE
color_scheme <- 'regular'
age_name <- 'age'
plot_type <- 'boxplot'

ages <- c(10, 20, 30, 40)
types <- c("rate", "time")

stat_test <- 'Y'
is_stat_test <- T
is_paired <- T


#############################################
# Parse command-line arguments
GetoptLong(
    "infiles=s@", "infiles",
    "m=s", "models",
    "y=s", "y axis name",
    "ymin=f", "ymin",
    "ymax=f", "ymax",
    "cat=s", "cat",
    "color!", "color",
    "by=s", "x axis: by model/calib",
    "age_name=s", "age|mu (default: age)",
    "plot_type=s", "boxplot|violin (default: boxplot)",
    "stat_test=s", "Y/N",
    "paired=s", "is_paired: Y/N"
    #"mu!", "mu"
)

if(is.null(y)){
    stop("y has to be given! Exiting ......")
}

if(!is.null(cat)){
    categories <- unlist(strsplit(cat, ",")) # Use unlist to get a character vector
}

if(is.null(m)){
    stop("model has to be given ......")
} else{
    selected_models <- unlist(strsplit(m, ',')) # Use unlist to get a character vector
}

if(color == TRUE){
    color_scheme <- 'rainbow'
} else{
    color_scheme <- 'regular'
}

# --- FIX: REMOVED STRAY 'n' CHARACTER ---
if(age_name == 'rate' || age_name == 'mu'){
    ages <- rev(c(-1.6, -2.3, -3, -3.7))
}

if(stat_test == 'N' || stat_test == 'F'){
    is_stat_test = F
}
if(paired == 'N' || paired == 'n' || paired == 'F'){
    is_paired = F
}


# Define the mapping for category names. This allows the script to read files
# with the old names but display the new names on the plot.
category_map <- c(
    "root" = "root_only",
    "calib-1_0.2--only_min" = "single_min",
    "calib-1_0.2" = "single_interval",
    "calib-2_0.2--only_min" = "two_min",
    "calib-2_0.2" = "two_intervals"
)

# Create a vector of the new category names, preserving the user-provided order.
# This will be used for setting factor levels and creating the legend.
new_categories <- categories
if (!is.null(categories)) {
    names_to_change <- new_categories %in% names(category_map)
    new_categories[names_to_change] <- category_map[new_categories[names_to_change]]
}


#############################################
par(mfrow = c(2, 2))

p <- list()

# Prepare a dummy plot for the legend using the NEW, user-friendly names
df_legend <- data.frame(x = 1, y = 1, Calibration = factor(new_categories, levels = new_categories))


# note: by calib then legend = model, vice versa
get_legend <- function(by){
    if(by == 'model'){
        legend_plot <- ggplot(df_legend, aes(x = x, y = y, color = Calibration, fill = Calibration))
    } else if(by == 'calib'){
        tmp_df <- data.frame(x=1, y=1, model=factor(selected_models, levels=selected_models))
        legend_plot <- ggplot(tmp_df, aes(x=x, y=y, color = model, fill = model))
    }
    legend_plot <- legend_plot +
        geom_point(alpha = 0, size = 5) +  # Set alpha to 0 to make the point transparent, adjust size for visibility in legend
        { if(color_scheme == 'rainbow'){ scale_color_manual(values = rev(c("red", "orange", "yellow", "green", "cyan", "blue", "purple"))) } } +
        guides(
            color = guide_legend(override.aes = list(alpha = 1)),  # Override alpha for legend
            fill = guide_legend(override.aes = list(alpha = 1))
        ) +
        theme_void() +
        theme(legend.position = 'bottom')
    return(legend_plot)
}

legend_plot <- get_legend(by)


###################################################
cat("ymax", ymax, "\n", sep="\t")
cat("paired", is_paired, "\n", sep="\t")


###################################################
for(type in types){
    for(ind in 1:length(ages)){
        age <- ages[ind]

        df_list <- list()
        # Loop over ORIGINAL categories to find the correct files
        for(cat_name in categories){
                file <- paste(cat_name, '-', type, '.', age, '.', y, sep="")
                if (!file.exists(file)) {
                    file <- paste(cat_name, "/", type, '.', age, ".", y, sep="")
                }
                if(!file.exists(file)){next}
            data <- read.table(file, header=T)
            colnames(data) <- gsub("\\.", "\\+", colnames(data))
            models <- rep(names(data), each=nrow(data))
            merged_data <- r_merge_list(data)
            # Assign ORIGINAL category name for now; it will be renamed later
            merged_data$Calibration <- cat_name
            merged_data$model <- models
            df_list[[cat_name]] <- merged_data
        }
        if (length(df_list) == 0) { next } # Skip if no files were found for this age/type
        df <- do.call(rbind, df_list)

        # Recode the Calibration column to the new names using the defined map
        df$Calibration <- dplyr::recode(df$Calibration, !!!category_map)

        # Set the factor levels using the new names, preserving the original order
        df$Calibration <- factor(df$Calibration, levels = new_categories)

        df <- df %>% filter(model %in% selected_models)
        df$model <- factor(df$model, levels = selected_models)

        if(by == 'model'){
            p[[ind]] <- ggplot(df, aes(x=model, y=score, fill=Calibration, color=Calibration)) + geom_boxplot(alpha=0.2, outlier.shape = outlier_shape)
        } else if(by == 'calib'){
            p[[ind]] <- ggplot(df, aes(x=Calibration, y=score, fill=model, color=model)) + {
                if(plot_type == 'boxplot'){
                    list(geom_boxplot(alpha=0.2, outlier.shape = outlier_shape))
                } else if(plot_type == 'beeswarm'){
                    list(geom_quasirandom(alpha = 0.7, size = 0.2, width = 0.2))
                } else if(plot_type == 'notched'){
                    list(
                        geom_boxplot(alpha=0.2, outlier.shape = 1, notch=T)
                    )
                } else if(plot_type == 'violin' || plot_type == 'violinplot'){
                    list(
                        geom_violin(alpha=0.2,position=position_dodge(0.8),draw_quantiles=c(0.5)),
                        geom_point(position=position_jitterdodge(jitter.width=0.2,dodge.width=0.8),alpha=0.4,size=0.001)
                    )
                } else{
                    stop("wrong type", plot_type, "exiting ......")
                }
            }

            if(color_scheme == 'rainbow'){
                p[[ind]] <- p[[ind]] + scale_color_manual(values = rev(c("red", "orange", "yellow", "green", "cyan", "blue", "purple")))
            }
        }

        if(age_name == 'age'){
            title <- paste('root age:', age/10, 'Ga')
        }else if(age_name == 'rate' || age_name == 'mu'){
            title <- paste('mean log(rate):', age, 'substitutions/site/Ga')
        }
        p[[ind]] <- p[[ind]] +
            ggtitle(title) + theme_bw() +
            theme(axis.title.x=element_blank(), axis.text.x = element_text(angle = 3*length(categories), hjust = 0.5, vjust = 0.5), plot.title = element_text(hjust = 0.5), legend.position = 'none') +
            ylab(y) + ylim(ymin, ymax) +
            if(is_stat_test){
                stat_compare_means(
                    data = function(d){
                        d %>% filter(model %in% c(selected_models[1], selected_models[length(selected_models)]))
                    },
                    method = "wilcox.test", paired=is_paired, label = "p.format", size=2.5, label.x.npc = "center", label.y = ymax * 0.95)
            }

        # Corrected bug: changed 'i' to 'ind'
        if(mu) { p[[ind]] <- p[[ind]] + geom_abline(intercept = 0.25, slope = 0, linetype="dashed", color='grey') }
    }

    # Ensure there are plots to draw before saving
    if (length(p) > 0) {
        combined_plot <- plot_grid(plotlist = p)
        final_plot <- plot_grid(legend_plot, combined_plot, ncol = 1, rel_heights = c(0.1, 1))
        final_plot <- final_plot + draw_label(type, x=0.5, y=0.97, fontface = "bold")

        ggsave(paste(type, '.', y, '.pdf', sep=''), final_plot, width = 8.27)
    }
    p <- list() # Reset plot list for the next 'type'
}
