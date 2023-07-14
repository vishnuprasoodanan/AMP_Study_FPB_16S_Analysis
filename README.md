# AMP_Study_FPB_16S_Analysis
The 16S sequence data for this analysis is generated by FPB

Alpha_Beta_Diversity_RScript: This script calculate three alpha diversity measures (Observed ASVs, Chao-1 and Shannon) and plot them as box-plots. Also, inter-sample distances were calculated using weighted/unweighted unifrac distances. The principal coordinate analysis has been carried out based on all 3 inter-sample distances mentioned above.

There are 4 input files for this script

1. ASV-table/feature-table/genus-count-table (In the script, it is mentioned as "Selected_FeatureTable_rarefied_edited.txt"). Both rarefied and non-rarefied feature-tables can be used as input. The values should be in integers. ASV-IDs/genus-names should be in rows and the samples should be in columns.

2. The metadata file (In the script, it is mentioned as "selected_Metadata.tsv"). This include the experiment, diet, vendor, gender etc. for each sample.
3. The taxonomy file ().
4. The taxonomic tree file ()
