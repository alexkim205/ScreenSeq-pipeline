library(readxl)
library(writexl)
library(dplyr)

source("functions.R")
source("parameters.R")

output_dir <- file.path(project_dir, "output")
dir.create(output_dir, showWarnings = FALSE)

## Write shRNA map xlsx with construct ids
{
  tgene_f <- pert_map_path
  tgene_fo <- file.path(output_dir, "pert_map_w_ids.xlsx")
  WRITE_CONSTRUCT_FILE <- TRUE
  
  tgene_df <- create_constructs(tgene_f, tgene_fo) # Region
}

## Load up barcodes 
{
  # barcodes_f <- paste0("../clean_data/fw_rv_pr_barcodes.xlsx")
  ### Create master plates list with barcodes
  plates <- create_plates(plate_ids, barcode_maps)
  ### Add target_gene data to plates list
  complete_plates <- add_gene_id(plates, tgene_df$construct)
}

## Write aggregate information by well
{
  WRITE_WELLS_FILE <- TRUE
  WRITE_PRINTSHEET_HELPER <- TRUE
  
  write_wells_info(output_dir, complete_plates, WRITE_WELLS_FILE, WRITE_PRINTSHEET_HELPER)
}

## Get Cell Quality Data


## Write YAML


## Get Perl Output


## Ridge Plots

