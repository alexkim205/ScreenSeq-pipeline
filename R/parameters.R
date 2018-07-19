######################
# General Parameters #
######################

## YAML Version
version <- 5.0

## Experiment Setup ~ Primary Parameters

project_dir <- "/Users/alexkim/Desktop/Gimelbrant/datamunge_test_project"
run <- "FUYANG"
pools <- c(1:7)
days <- c("D12", "D19", "D19")
replicates <- c("R3", "R2", "R3")
timestamp <- c("20171016", "20171023", "20171023")

### Constructs/Perturbations
constructs_map_path <- "clean_data/constructs"
constructs_maps <- c("DBI31","DBI31","DBI31") 

### Barcodes
barcode_maps_path <- "clean_data/barcodes"
barcode_maps <- c("P1a","P1", "P2") # P3, P4

### Cell Qualities
cell_quals_path <- "clean_data/cell_quals"
cell_quals <- paste0(timestamp, "_", plate_ids, "_cellqual.xlsx")

### Plate identifiers ~ Don't edit
plate_ids <- paste0(constructs_maps,"_",days,"_",replicates)

## YAML Parameters
UMI <- FALSE
SNP <- TRUE
well_alpha <- LETTERS[1:8]
well_numer <- c(1:12)

## step 2 output
s2_result_path <- "output"
s2_result <- "s2_output.txt"

## alignment
### the following applies to step 1:::
fastq_dir <- "clean_data/fastq"
R1 <- "R1_test.fastq"
R2 <- "R2_test.fastq"
reference <- "mm10"
### the following applies to step 1 + step 2:::
SAM_name_base <- "FUYANG_6-5_mm10"
SAM_location <- "output/sam"

## genes
### temporary solution until I figure out where these genes are coming from
genes_l <- list(
  NM_010954_Ncam2_MAE = list(
    SNPFlank_left = "CATACAATT",
    position = "chr16:81596071-81596364",
    amplicon_size = 294
  ),
  NM_194355_Spire1_MAE = list(
    SNPFlank_left = "ACGGAGTGT",
    position = "chr18:67490796-67491034",
    amplicon_size = 239
  )
)

#####################
# Hidden Parameters #
#####################

## Barcode Generation

## Scripts
scripts_path <- "scripts/perl"
UMI_script <- "ast_umi_v41.pl"
SNP_script <- "ast_snpv62X.pl"
s2_script <- "step2v52X.pl"
#~ asymagic: as2.pl

## Diagnostics
DEBUG <- TRUE
use_existing_sorted_SAM <- FALSE
leave_SAM <- FALSE
TryRevComp <- FALSE
output_yaml <- FALSE

## Step 2
minimal_MAPQ <- 12
### global limits on insert length  (for sanity)
insert_len_min <- 25
insert_len_max <- 700
### amplicon_size +/- this is allowed:
amplicon_size_tolerance <- 100
#~ umiPattern <- "A11 A*"
UMInoSNPpattern <- "A7 A6 A18 A11 A*"
SNPnoUMIpattern <- "A7 A6 A18 A*"
#~ ignore_T2_small <- "CGTGGAATCGCT"
#~ T2_small <- "TCGCTAAAACG"
T2_small <- "TCGCTAATTGC"
MINflankLength <- 6

