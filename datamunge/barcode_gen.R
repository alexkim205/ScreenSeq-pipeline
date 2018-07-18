library(readxl)
library(writexl)
library(dplyr)

source("functions.R")
source("parameters.R")

## Write shRNA map xlsx with construct ids
tgene_f <- paste0("../clean_data/", pert_map, "_wo_ids.xlsx")
tgene_fo <- paste0("../output/", pert_map, "_w_ids.xlsx")
WRITE_CONSTRUCT_FILE <- TRUE

tgene_df <- create_constructs(tgene_f, tgene_fo)

## Load up barcodes 
barcodes_f <- paste0("../clean_data/fw_rv_pr_barcodes.xlsx")
barcodes_fo <- paste0("../output", barcode_map, "_map.ods.xlsx")
WRITE_WELLS_FILE <- TRUE
WRITE_PRINTSHEET_HELPER <- TRUE

### Create master plates list with barcodes
plates <- create_plates(plate_ids, barcode_maps)
### Add target_gene data to plates list
complete_plates <- add_gene_id(plates, tgene_df$`Construct ID`)

## Aggregate information by well
write_wells_info(project_dir, complete_plates, WRITE_WELLS_FILE, WRITE_PRINTSHEET_HELPER)

