ScreenSeq Pipeline README.Rmd
================
Alex Kim
7/19/2018

## Background

This pipeline for the ScreenSeq technique was created to make running
experiments using this technology easier. Current methods involve
copying data from one spreadsheet to another to configuration files
which is time consuming and error prone. This attempts to make that
process less painful.

*Future work* would include R Shiny apps that augment experiment design
and data input (cell viability).

## Usage

I plan to make this into a package so that the functions can be used
modularly, but for now the user will have to open up the `.R` files in
the `R/` directory manually.

1.  Open up `datamunge.Rproj` with RStudio.
2.  Open the following files: `functions.R`, `main.R`, `make_project.R`,
    `parameters.R`
3.  Make sure your current working directory is same folder that
    `datamunge.Rproj` is in with `getwd()`. Use `setwd()` if otherwise.

### `make_project.R`

This file contains one helper function that allows the user to generate
the correct folder hierarchy for any experimental run. Use this function
to ensure that the program runs smoothly.

You can read the in-depth documentation of what the function exactly
does in `man/make_project.Rd`.

An
example:

``` r
project_dir <- "/Users/alexkim/Desktop/Gimelbrant/datamunge_test_project"
project_run_name <- "HONDA"
pools <- c(1:7)

# haven't finished writing this function yet
# make_project(project_dir, project_run_name, pools, overwrite=TRUE)
```

### `parameters.R`

This is where the user will be defining the experimental parameters. A
more in-depth explanation of these parameters follows below:

#### General Parameters

``` r
## YAML Version
version <- 5.0
```

*Experiment Setup*

The `project directory` is the path at which you want to create a
project folder called FUYANG, or whatever `run` is, inside of. `pools`
specifies how many pools are in the `run`. See function documentation
for `make_project()` for more details on this.

Specify same-length vectors for `days`, `replicates`, `timestamp`, and
`constructs_maps` to create a concatenated identifier for each plate.

``` r
### Primary Parameters
project_dir <- "/Users/alexkim/Desktop/Gimelbrant/datamunge_test_project"
run <- "FUYANG"
pools <- c(1:7)
days <- c("D12", "D19", "D19")
replicates <- c("R3", "R2", "R3")
timestamp <- c("20171016", "20171023", "20171023")
well_alpha <- LETTERS[1:8] # A - H
well_numer <- c(1:12)      # 1 - 12
```

The `constructs_map_path`, `barcodes_map_path`, and
`cell_quals_map_path` paths are all relative to the project\_dir. For
example, the absolute path for `constructs_maps[1]` will be
`/Users/alexkim/Desktop/Gimelbrant/datamunge_test_project/constructs/DBI31.xlsx`.

Keep in mind that all directory paths from here on out will be relative
to the `project_dir` specified above.

``` r
### Constructs/Perturbations
constructs_map_path <- "constructs"
constructs_maps <- c("DBI31","DBI31","DBI31") 

### Barcodes
barcode_maps_path <- "barcodes"
barcode_maps <- c("P1a","P1", "P2") # P3, P4

### Generate Plate Identifiers ~ Don't touch
plate_ids <- paste0(constructs_maps,"_",days,"_",replicates)
plate_ids
```

    ## [1] "DBI31_D12_R3" "DBI31_D19_R2" "DBI31_D19_R3"

``` r
### Cell Qualities
cell_quals_path <- "cell_viabilities"
cell_quals <- paste0(timestamp, "_", plate_ids, "_cellqual.xlsx")
```

*YAML Configuration File*

These parameters are required to create the `.yaml` file input for
Sasha’s `s1.sh` and `s2.sh` scripts which align and performs a SNP
count.

The key parameters that you’ll be changing here are `s2_result_path`,
`s2_result`, `fastq_dir`, `R1`, `R2`.

``` r
## YAML Parameters
UMI <- FALSE
SNP <- TRUE
```

Where you want the perl scripts to output the SNP count data file.

``` r
## step 2 output
s2_result_path <- "output"
s2_result <- "s2_output.txt"
```

There should be files called `{run}_{pool_number}_R1.fastq` and
`{run}_{pool_number}_R2.fastq` in their respective pool folders in the
`fastq/` folder in the project directory. If this confuses you, check
out the function documentation for `make_project()` for more details on
the file hierarchy of the project directory.

``` r
## alignment
### the following applies to step 1:::
fastq_dir <- "fastq"
R1 <- "R1.fastq"
R2 <- "R2.fastq"
reference <- "mm10"
```

Where the alignment `.sam` files should end up.

``` r
### the following applies to step 1 + step 2:::
SAM_name_base <- "FUYANG_6-5_mm10"
SAM_location <- "output"
```

Copy and paste genes from `.yaml`’s in list form.

``` r
## genes
### temporary solution until I figure out where these genes are coming from, please put into this list format
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
```

#### Hidden Parameters

These parameters will probably not have to be changed.

``` r
## Barcode Generation <-- To be implemented

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
```

### `function.R`

See documentation for each function in `man/` folder.

### `main.R`

This is where everything is integrated.
