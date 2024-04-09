#final version of kappa plots
library(tidyverse)
library(cowplot)
library(ggpubr)
library(ggforce)
library(rstatix)

data_files = list.files(path = ".", pattern = ".csv", full.names=TRUE, recursive=TRUE)
data_files <- data_files[! data_files %in% c("./curves_to_check.csv")]
conditions = basename(dirname(data_files))
files = basename(data_files)
labels = paste(conditions, files, sep = ":")

data <- lapply(data_files, read.csv)
names(data) <- labels

df <- data |> dplyr::bind_rows(.id = "ID") |>
    tidyr::separate_wider_delim(cols = "ID", delim = ":", names = c("Condition", "File"))

clean_colnames <- janitor::make_clean_names(colnames(df), case = "snake")
colnames(df) <- clean_colnames

df_final <- df |>
    dplyr::mutate(condition = str_remove(condition, pattern = "-csv")) |>
    dplyr::filter(condition %in% c("2B", "2Q", "WT", "2B-XL")) |>
    dplyr::filter(file != "SUM_ 16q_clone_1.nd2 - 16q_clone_1.nd2 (series 6)-1-1_F.csv" & curve_name != "CURVE 5")

#now get area under curve for each curve x vs. point curvature
df_auc <- df_final |>
    dplyr::group_by(condition, file, curve_name) |>
    dplyr::mutate(AUC = MESS::auc(x=x_coordinate_um, y = point_curvature_um_1, absolutearea = TRUE)) |>
    dplyr::ungroup() |>
    dplyr::select(condition, file, curve_name, average_curvature_um_1, curve_length_um, AUC) |>
    dplyr::distinct() |>
    dplyr::mutate(condition = factor(condition, levels = c("WT", "2B", "2B-XL", "2Q")))

#Let's add a "Radius" column - the average curvature is in units 1/R, so it should just be the inverse of the average curvature

df_auc_radius <- df_auc |>
    dplyr::mutate(radius = 1/average_curvature_um_1)

my_comparisons <- list( c("WT", "2B"), c("WT", "2B-XL"), c("WT", "2Q") )
ggplot(df_auc, aes(x=condition, y=log2(AUC), fill=condition)) +
    geom_violin(width=0.5, color="black", alpha=0.7, draw_quantiles = c(0.25, 0.5, 0.75)) +
    scale_fill_manual(name = "Strain",
                      values = c("WT" = "grey",
                                 "2B" = "gold",
                                 "2B-XL" = "magenta",
                                 "2Q" = "blue")) +
    geom_point(color="black") +
    stat_compare_means(method= "kruskal", label.y=6) +
    stat_compare_means(method = "wilcox", comparisons = my_comparisons, p.adjust.method = "BH") +
    xlab("") +
    ylab("log2 - AUC") +
    theme_cowplot(font_size = 18)
ggsave2("./Kappa_plots_log2_AUC_point_curvature.pdf", height=6, width=6, units="in")

ggplot(df_auc, aes(x=condition, y=log2(average_curvature_um_1), fill = condition)) +
    geom_violin(width=0.5, color="black", alpha=0.7, draw_quantiles = c(0.25, 0.5, 0.75)) +
    scale_fill_manual(name = "Strain",
                      values = c("WT" = "grey",
                                 "2B" = "gold",
                                 "2B-XL" = "magenta",
                                 "2Q" = "blue")) +
    #geom_boxplot(width=0.1, fill = "white", alpha=0.4) +
    geom_point(color="black") +
    stat_compare_means(method= "kruskal", label.y=6) +
    stat_compare_means(method = "wilcox", comparisons = my_comparisons, p.adjust.method = "BH") +
    xlab("") +
    ylab("log2 - Avg. Curvature") +
    theme_cowplot(font_size = 18)
ggsave2("./Kappa_plots_log2_average_curvature.pdf", height=6, width=6, units="in")

#plot the distributions of average radius of the spindles
ggplot(df_auc_radius, aes(x=condition, y=log2(radius), fill=condition)) +
    geom_violin(width=0.5, color="black", alpha=0.7, draw_quantiles = c(0.25, 0.5, 0.75)) +
    scale_fill_manual(name = "Strain",
                      values = c("WT" = "grey",
                                 "2B" = "gold",
                                 "2B-XL" = "magenta",
                                 "2Q" = "blue")) +
    geom_point(color="black", show.legend = F) +
    stat_compare_means(method= "kruskal", label.y=12) +
    stat_compare_means(method = "wilcox", comparisons = my_comparisons, p.adjust.method = "BH") +
    xlab("") +
    ylab("log2-Average Radius (microns)") +
    theme_cowplot(font_size = 18)
ggsave2("./Kappa_plots_log2_average_radius.pdf", height=6, width=6, units="in")


#Summary Stats by condition
df_auc_radius |>
    dplyr::mutate(log2_auc = log2(AUC),
                  log2_radius = log2(radius)) |>
    dplyr::group_by(condition) |>
    rstatix::get_summary_stats(type = "full") |>
    write.csv("./summary_stats_for_legends.csv")

df_auc_radius |>
    dplyr::mutate(log2_auc = log2(AUC),
                  log2_radius = log2(radius)) |>
    dplyr::group_by(condition) |>
    rstatix::shapiro_test(vars = c("AUC", "radius", "log2_auc", "log2_radius")) |>
    write.csv("./shaprio_wilks_test_results.csv")

