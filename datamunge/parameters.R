######################
# General Parameters #
######################

## YAML Version
version <- 5.0

## Experiment Setup
project_dir <- "/Users/alexkim/Desktop/Gimelbrant/datamunge"
run <- "FUYANG"
pert_map_path <- "../clean_data/DBI31_wo_ids.xlsx"
pert_maps <- c("DBI31","DBI31","DBI31") ## TODO
barcode_maps_path <- "../clean_data/barcodes/"
barcode_maps <- c("P1a","P1", "P2") # P3, P4
days <- c("D12", "D19", "D19")
replicates <- c("R3", "R2", "R3")
date <- c("20171016", "20171023", "20171023")
UMI <- FALSE
SNP <- TRUE
plate_ids <- paste0(pert_maps,"_",days,"_",replicates) # shRNA map

well_alpha <- LETTERS[1:8]
well_numer <- c(1:12)

## step 2 output
result <- "main_output_file.txt"

## alignment
### the following applies to step 1:::
fastq_dir <- "/n/scratch2/ak583/screenseq/FUYANG/fastq"
R1 <- "R1_test.fastq"
R2 <- "R2_test.fastq"
reference <- "mm10"
### the following applies to step 1 + step 2:::
SAM_name_base <- "FUYANG_6-5_mm10"
SAM_location <- "/home/ak583/Gimelbrant_Lab/scratch/screenseq/FUYANG/sam_old"

## genes

#####################
# Hidden Parameters #
#####################

## Barcode Generation

## Scripts
location <- "/n/scratch2/ak583/screenseq/FUYANG/scrpt/perl"
UMI_script <- "ast_umi_v41.pl"
SNP_script <- "ast_snpv62X.pl"
s2 <- "step2v52X.pl"
# asymagic: as2.pl

## Diagnostics
DEBUG <- TRUE
use_existing_sorted_SAM <- FALSE
leave_SAM <- FALSE
TryRevComp <- FALSE