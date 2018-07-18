######################
# General Parameters #
######################

version <- 5.0

## experiment
project_dir <- "/Users/alexkim/Desktop/Gimelbrant/datamunge"
run <- "FUYANG"
pert_map <- "DBI31"
barcode_maps_path <- "../clean_data/barcodes/"
barcode_maps <- c("P1a","P1", "P2") # P3, P4
days <- c("D12", "D19", "D19")
replicates <- c("R3", "R2", "R3")
plate_ids <- paste0(days,"_",replicates)
well_alpha <- LETTERS[1:8]
well_numer <- c(1:12)

## alignment
### the following applies to step 1:::
fastq_dir <- "/n/scratch2/ak583/screenseq/FUYANG/fastq"
R1 <- "R1_test.fastq"
R2 <- "R2_test.fastq"
reference <- "mm10"
### the following applies to step 1 + step 2:::
SAM_name_base <- "FUYANG_6-5_mm10"
SAM_location <- "/home/ak583/Gimelbrant_Lab/scratch/screenseq/FUYANG/sam_old"

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