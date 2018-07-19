######################
# General Parameters #
######################

## YAML Version
version <- 5.0

## Experiment Setup ~ Primary Parameters

project_dir <- "/Users/alexkim/Desktop/Gimelbrant/datamunge"
run <- "FUYANG"
days <- c("D12", "D19", "D19")
replicates <- c("R3", "R2", "R3")
timestamp <- c("20171016", "20171023", "20171023")
plate_ids <- paste0(pert_maps,"_",days,"_",replicates)

### Constructs/Perturbations
constructs_map_path <- "clean_data/constructs"
constructs_maps <- c("DBI31","DBI31","DBI31") 

### Barcodes
barcode_maps_path <- "clean_data/barcodes"
barcode_maps <- c("P1a","P1", "P2") # P3, P4

### Cell Qualities
cell_quals_path <- "clean_data/cell_quals"
cell_quals <- paste0(timestamp, "_", plate_ids, "_cellqual.xlsx")


## Secondary Parameters
UMI <- FALSE
SNP <- TRUE
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