#This Script is created by Vishnu Prasoodanan P K
#It will take phylum-level feature table (i.e, ASV count at phylum level) and metadata file. Then it will convert the count values to relative abundance. 
#Then separate the relative abundance data of each experiment, then separate the relative abundance data of each source (MAB and content).
#Then it will plot stacked barplot for each relative abundance data for experiment-source combinations

library(tidyr)
library(tibble)
library(tidyverse)
library(plyr)
library(dplyr)
library(reshape2)
library(phyloseq)
library (ape)
library (ggplot2)
library(vegan)
library(RColorBrewer)

p_data <- read.table(file = "phylum_feature_table.txt", sep = "\t", header = T, row.names = 1)
p_data_filtered <- p_data[rowSums(p_data) >= 1, ]
#p_data_filtered <- p_data_filtered[colSums(p_data_filtered) != 0, ]
p_data_filtered  <- p_data_filtered [, colSums(p_data_filtered ) != 0]

df <- p_data_filtered
names(df) <- gsub("^X", "", names(df))
names(df) <- gsub("\\.", "-", names(df))
# calculate the relative abundance
df <- as.data.frame(t(df))
df_relative <- t(apply(df, 1, function(x) x/sum(x)))

# transpose the result back to its original orientation
df_relative <- as.data.frame(t(df_relative))
write.table(df_relative, file = "sel_feature_table_abundance.txt", sep = '\t', quote = FALSE, row.names = TRUE)

#----------------------------------------------------------------------------------------
#experimwnt-wise separation of data

#otu_table_in <- read.csv("sel_feature_table_abundance.txt", sep = "\t")
otu_table_in <- df_relative
otu_table_t <- as.data.frame(t(otu_table_in ))

#otu_table_t <- setNames(data.frame(t(otu_table_in[,-1])), otu_table_in[,1])
otu_table_t <- tibble::rownames_to_column(otu_table_t)

names(otu_table_t)[names(otu_table_t) == "rowname"] <- "SampleID"

otu_table_t$SampleID <- gsub('^[X]', '', otu_table_t$SampleID) 
otu_table_t$SampleID <- gsub('[.]', '-', otu_table_t$SampleID)

metadata_all <- read.table("selected_Metadata.tsv", sep="\t", row.names = 1, header=T)
metadata_all <- tibble::rownames_to_column(metadata_all)
names(metadata_all)[names(metadata_all) == "rowname"] <- "SampleID"

merge_otu_table_t <- merge(otu_table_t, metadata_all, by.x = "SampleID")
merge_otu_table_t$experiment <- as.factor(merge_otu_table_t$experiment)
merge_otu_table_t$source <- as.factor(merge_otu_table_t$source)
# Get the factor column name
factor_column <- "experiment"

# Iterate through each factor variable in experiment
factor_levels <- levels(merge_otu_table_t[[factor_column]])
for (level in factor_levels) {
  # Filter the data frame for the current factor level
  Si8_FP001 <- merge_otu_table_t[merge_otu_table_t[[factor_column]] == level, ]
  numeric_columns <- Si8_FP001[, sapply(Si8_FP001, is.numeric)]
  numeric_columns <- numeric_columns[, colSums(numeric_columns) > 0]
  
  non_numeric_columns <- Si8_FP001[, !sapply(Si8_FP001, is.numeric)]
  
  # Create a new data frame
  filtered_df <- data.frame(numeric_columns, non_numeric_columns)
  row.names(filtered_df) <- Si8_FP001$SampleID
  
  Si8_FP001_Final1 <- as.data.frame(t(filtered_df[,1:(ncol(filtered_df)-8)]))
  Si8_FP001_Metadata1 <- filtered_df[,(ncol(filtered_df)-7):ncol(filtered_df)]
  Si8_FP001_Metadata <- rownames_to_column(Si8_FP001_Metadata1, var = "RowID")
  colnames(Si8_FP001_Metadata)[1] <- "SampleID"
  Si8_FP001_Final <- rownames_to_column(Si8_FP001_Final1, var = "RowID")
  colnames(Si8_FP001_Final)[1] <- "SampleID"
  file_name1 <- paste(level, "_feature-table.txt", sep = "_")
  file_name2 <- paste(level, "_Metadata.txt", sep = "_")
  write.table(Si8_FP001_Final, file = file_name1, sep = "\t", quote = FALSE, row.names = FALSE)
  write.table(Si8_FP001_Metadata, file = file_name2, sep = "\t", quote = FALSE, row.names = FALSE)
  filtered_df$source <- as.factor(filtered_df$source)
  factor_column2 <- "source"
  factor_levels2 <- levels(filtered_df[[factor_column2]])
  # Iterate through each factor variable in source (content and MAB)
  for (level2 in factor_levels2) {
    gut <- filtered_df[filtered_df[[factor_column2]] == level2, ]
    numeric_columns2 <- gut[, sapply(gut, is.numeric)]
    numeric_columns2 <- numeric_columns2[, colSums(numeric_columns2) > 0]
    
    non_numeric_columns2 <- gut[, !sapply(gut, is.numeric)]
    # Create a new data frame
    filtered_df2 <- data.frame(numeric_columns2, non_numeric_columns2)
    row.names(filtered_df2) <- gut$SampleID
    gut_Final1 <- as.data.frame(t(filtered_df2[,1:(ncol(filtered_df2)-8)]))
    gut_Metadata1 <- filtered_df2[,(ncol(filtered_df2)-7):ncol(filtered_df2)]
    gut_Metadata <- rownames_to_column(gut_Metadata1, var = "RowID")
    colnames(gut_Metadata)[1] <- "SampleID"
    gut_Final <- rownames_to_column(gut_Final1, var = "RowID")
    colnames(gut_Final)[1] <- "SampleID"
    file_name3 <- paste(level, level2, "_feature-table.txt", sep = "_")
    file_name4 <- paste(level, level2, "_Metadata.txt", sep = "_")
    write.table(gut_Final, file = file_name3, sep = "\t", quote = FALSE, row.names = FALSE)
    write.table(gut_Metadata, file = file_name4, sep = "\t", quote = FALSE, row.names = FALSE)
    
    gut_Final_v1 <- as.data.frame(t(gut_Final1))
    gut_Final_v1 <- tibble::rownames_to_column( gut_Final_v1)
    names(gut_Final_v1)[names(gut_Final_v1) == "rowname"] <- "SampleID"
    gut_Metadata_v1 <- gut_Metadata
    gut_Metadata_v2 <- gut_Metadata_v1[, -c(1, 2, 4:7)]
    gut_Final_v2 <- merge(gut_Final_v1, gut_Metadata_v2, by.x = "SampleID")
    
    gut_Final_diet <- gut_Final_v2 %>% select(SampleID, diet, everything())%>% select(-sex)
    row.names(gut_Final_diet) <- gut_Final_diet$SampleID
    gut_Final_diet1 <- gut_Final_diet[, -1]
    combined <- paste(gut_Final_diet1$diet, rownames(gut_Final_diet1), sep = "_")
    row.names(gut_Final_diet1) <- combined
    gut_Final_diet1$diet <- NULL
    gut_Final_diet_t <- as.data.frame(t(gut_Final_diet1))
    gut_Final_diet_t <- tibble::rownames_to_column(gut_Final_diet_t)
    names(gut_Final_diet_t)[names(gut_Final_diet_t) == "rowname"] <- "Name"
    # Calculate row sums excluding first column
    row_sums <- rowSums(gut_Final_diet_t[, -1])
    
    # Find the indices of the rows with the 5 highest row sums
    top_rows <- order(row_sums, decreasing = TRUE)[1:5]
    
    # Select the rows with the 5 highest row sums
    df_top <- gut_Final_diet_t[top_rows, ]
    
    # Calculate column sums
    column_sums <- 1-(colSums(df_top[, -1]))
    
    # Create a new row with column sums and label "Others"
    sum_row <- data.frame(Name = "Others", t(column_sums))
    names(sum_row) <- gsub("\\.", "-", names(sum_row))
    # Add the new row as the last row of the dataframe
    df_with_sum_row <- rbind(df_top, sum_row)
    
    df <- df_with_sum_row 
    data_order <- df[order(apply(df, 1, min)),]
    # convert data from wide to long format using tidyr
    df_long <- pivot_longer(df, cols = -Name, names_to = "Sample", values_to = "Abundance")
    colors_p <- c("#1F77B4", "#FF7F0E", "#2CA02C", "#D62728", "deepskyblue", "gray")
    colors_g <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
                "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf",
                "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5",
                "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", "gray")
    
    #colors_g <- c("#1F77B4", "#FF7F0E", "#2CA02C", "#D62728", "deepskyblue", "goldenrod1", "darkolivegreen", "salmon", "mediumpurple3", "paleturquoise4", "goldenrod4", "#FF00FF", "#F433FF", "#E600FF", "#CC00FF", "#B266FF","#9B30FF", "#8800FF", "#660066", "#993399", "#CC66CC", "#FF33CC", "#FF0099", "gray")
    # create stacked barplot using ggplot2
    
    header1 <- paste(level, level2, "_phylum_relative_abundance", sep = "_")
    file_name5 <- paste(level, level2, "_phylum_abundance_diet.pdf", sep = "_")
    p<- ggplot(df_long, aes(x = Sample, y = Abundance, fill = Name)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = colors_p) +
        labs(title = header1, x = "Sample", y = "Relative Abundance") +
        theme(axis.text.x = element_text(angle = 90, hjust = 1))
    ggsave(file_name5, p, width = 25, height = 10, limitsize = FALSE)
    
    data <- gut_Final_diet
    rownames(data) <- NULL
    # Compute average abundance by group
    group_averages<- data %>% group_by(diet) %>% dplyr::summarize(across(starts_with("d__"), mean))
    
    file_name6 <- paste(level, level2, "_average_group_abundance.txt", sep = "_")
    write.table(group_averages, file = file_name6, sep = '\t', quote = FALSE, row.names = FALSE)

    group_averages_cs <- colSums(group_averages[, -1])
    
    # Find the names of the columns with the 20 highest column sums
    group_averages_top_columns <- names(group_averages_cs)[order(group_averages_cs, decreasing = TRUE)[1:5]]
    
    # Select the columns with the 20 highest column sums
    group_averages_top_20 <- group_averages[, c("diet", group_averages_top_columns)]
    group_averages_top_21 <- group_averages_top_20 %>% mutate(Others = 1-(rowSums(select(., -1))))
    
    #group_averages_top_21 <- group_averages_top_20 %>% mutate(Others = 1-(rowSums(.)))
    group_averages_long <- pivot_longer(group_averages_top_21, cols = -diet, names_to = "SampleID", values_to = "Abundance")
    # create stacked barplot using ggplot2
    file_name7 <- paste(level, level2, "_average_group_abundance.pdf", sep = "_")
    header2 <- paste(level, level2, "_Phylum_group_average_relative_abundance", sep = "_")
    q <- ggplot(group_averages_long, aes(x = diet, y = Abundance, fill = SampleID)) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = colors_p) +
      labs(title = header2, x = "diet", y = "Average Relative Abundance") +
      theme(axis.text.x = element_text(angle = 90, hjust = 1))
    ggsave(file_name7, q, width = 7, height = 10, limitsize = FALSE)
  }
}
