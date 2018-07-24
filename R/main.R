#!/usr/bin/env Rscript

## Set working directory to directory of this file which is `R/`
cat("Setting working directory to R/\n")
{
  setwd(file.path(getwd(), "R")) # alternative change sources to R/
}

source("parameters.R")
source("functions.R")
source("make_project.R")

## Argument parser
cat("Parsing arguments\n")
{
  ### `Rscript main.R {plate_basename}.yaml`
  args <- commandArgs(trailingOnly=TRUE)
  yaml_f <- read_arguments(args)
  
  ### get plate_name
  cat(" - Getting plate name\n")
  plate_name <- tools::file_path_sans_ext(basename(yaml_f))
  
  ### Read in parameters into global namespace
  cat(" - Defining parameters\n")
  read_parameters(yaml_f)
}

## Create project directory structure
cat("Creating project folder\n")
{
  ### Globally defines project_dir, outputs_dir
  cat(" - Getting project paths\n")
  make_project(output_path, plate_name, overwrite = TRUE) 
}

## Create plates
cat("Creating master plates\n")
{
  ### Get barcodes
  cat(" - Getting barcodes\n")
  {
    #### Create master plates list with barcodes
    cat("  - Populate plates with barcodes\n")
    barcode_maps_f <- file.path(barcode_maps_path, paste0(barcode_maps, ".xlsx"))
    plates.bc <- create_plates(plate_ids, barcode_maps_f)
  }
  
  ### Get Construct/Perturbation ID's
  cat(" - Getting perturbations\n")
  {
    constructs_f <- file.path(constructs_map_path, paste0(constructs_maps, ".xlsx"))
    constructs_fo <- file.path(outputs_dir, paste0(constructs_maps, "_w_ids.xlsx"))
    WRITE_CONSTRUCT_FILE <- TRUE
    
    constructs_list <- get_constructs(plate_ids, constructs_f, constructs_fo, WRITE_CONSTRUCT_FILE) # Region
    
    #### Add construct id data to plates list
    cat("  - Populate plates with perturbations\n")
    plates.bc.cst <- add_lists_to_plates(plates.bc, "construct", constructs_list)
  }
  
  ### Get Cell Viability Data
  cat(" - Getting cell viability data\n")
  {
    #### Get clean data from Shiny App
    cell_quals_f <- file.path(cell_quals_path, cell_quals)
    
    cell_quals_list <- get_cell_qualities(plate_ids, cell_quals_f)
    
    #### Add cell_quality data to plates list
    cat("  - Populate plates with cell viabilities\n")
    plates.bc.cst.cq <- add_lists_to_plates(plates.bc.cst, "cell_quality", cell_quals_list)
  }
}


## Write well YAML
cat("Writing master plates to yaml\n")
{
  WRITE_WELLS_FILE <- TRUE
  WRITE_PRINTSHEET_HELPER <- TRUE
  
  write_wells_info(outputs_dir, plates.bc.cst.cq, WRITE_WELLS_FILE, WRITE_PRINTSHEET_HELPER)
}


## Write config YAML
cat("Writing configuration yaml\n")
{
  yaml_fo <- file.path(project_dir, "config", paste0(run, ".yaml"))
  
  write_config_yaml(plates.bc.cst.cq, yaml_fo)
}

## Run Step 1 - Alignment and Step 2 - Count
cat("Running perl scripts\n")
{
  ### Step 1
  cat(" - Aligning\n")
  run_s1(yaml_fo, doS1)
  
  ### Step 2
  cat(" - Counting\n")
  run_s2(yaml_fo, doS2)
}

## Get Perl Output


## Ridge Plots

