#!/usr/bin/env Rscript

# Set working directory to directory of this file which is R/
dir_of_this_file <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dir_of_this_file)

source("parameters.R")
source("functions.R")
source("make_project.R")

# Argument parser
## `Rscript main.R /Users/alexkim/Dropbox/Gimelbrant_Lab/datamunge_test_project/plate1.yaml`
args <- commandArgs(trailingOnly=TRUE)
yaml_f <- read_arguments(args)

## get plate_name
plate_name <- tools::file_path_sans_ext(basename(yaml_f))

## Read in parameters into global namespace
read_parameters(yaml_f)

## Create project directory structure
### Globally defines project_dir, outputs_dir
make_project(output_path, plate_name, overwrite = TRUE)

## Get barcodes
{
  ### Create master plates list with barcodes
  barcode_maps_f <- file.path(barcode_maps_path, paste0(barcode_maps, ".xlsx"))
  plates.bc <- create_plates(plate_ids, barcode_maps_f)
}

## Get Construct/Perturbation ID's
{
  constructs_f <- file.path(constructs_map_path, paste0(constructs_maps, ".xlsx"))
  constructs_fo <- file.path(outputs_dir, paste0(constructs_maps, "_w_ids.xlsx"))
  WRITE_CONSTRUCT_FILE <- TRUE
  
  constructs_list <- get_constructs(plate_ids, constructs_f, constructs_fo, WRITE_CONSTRUCT_FILE) # Region
  
  ### Add construct id data to plates list
  plates.bc.cst <- add_lists_to_plates(plates.bc, "construct", constructs_list)
}


## Get Cell Quality Data

### Get clean data from Shiny App
{
  cell_quals_f <- file.path(cell_quals_path, cell_quals)
  
  cell_quals_list <- get_cell_qualities(plate_ids, cell_quals_f)
  
  ### Add cell_quality data to plates list
  plates.bc.cst.cq <- add_lists_to_plates(plates.bc.cst, "cell_quality", cell_quals_list)
}


## Write well YAML
{
  WRITE_WELLS_FILE <- TRUE
  WRITE_PRINTSHEET_HELPER <- TRUE
  
  write_wells_info(outputs_dir, plates.bc.cst.cq, WRITE_WELLS_FILE, WRITE_PRINTSHEET_HELPER)
}


## Write config YAML
{
  yaml_fo <- file.path(project_dir, "config", paste0(run, ".yaml"))
  
  write_config_yaml(plates.bc.cst.cq, yaml_fo)
}

## Run Step 1 - Alignment and Step 2 - Count
{
  run_s1(yaml_fo, doS1)
  run_s2(yaml_fo, doS2)
}

## Get Perl Output


## Ridge Plots

