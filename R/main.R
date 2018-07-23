source("R/parameters.R")
source("R/functions.R")
source("R/make_project.R")

yaml_f <- "/Users/alexkim/Dropbox/Gimelbrant_Lab/datamunge_test_project/plate1.yaml"
plate_name <- tools::file_path_sans_ext(basename(yaml_f))

## Read in parameters into global namespace
read_parameters(yaml_f)

## Create project directory structure
project_dir <<- make_project(output_path, plate_name, overwrite = TRUE)

## Get barcodes
{
  ### Create master plates list with barcodes
  barcode_maps_f <- file.path(project_dir, barcode_maps_path, paste0(barcode_maps, ".xlsx"))
  plates.bc <- create_plates(plate_ids, barcode_maps_f)
}


## Get Construct/Perturbation ID's
{
  constructs_f <- file.path(project_dir, constructs_map_path, paste0(constructs_maps, ".xlsx"))
  constructs_fo <- file.path(output_dir, paste0(constructs_maps, "_w_ids.xlsx"))
  WRITE_CONSTRUCT_FILE <- TRUE
  
  constructs_list <- get_constructs(plate_ids, constructs_f, constructs_fo, WRITE_CONSTRUCT_FILE) # Region
  
  ### Add construct id data to plates list
  plates.bc.cst <- add_lists_to_plates(plates.bc, "construct", constructs_list)
}


## Get Cell Quality Data

### Get clean data from Shiny App
{
  cell_quals_f <- file.path(project_dir, cell_quals_path, cell_quals)
  
  cell_quals_list <- get_cell_qualities(plate_ids, cell_quals_f)
  
  ### Add cell_quality data to plates list
  plates.bc.cst.cq <- add_lists_to_plates(plates.bc.cst, "cell_quality", cell_quals_list)
}


## Write well YAML
{
  WRITE_WELLS_FILE <- TRUE
  WRITE_PRINTSHEET_HELPER <- TRUE
  
  write_wells_info(output_dir, plates.bc.cst.cq, WRITE_WELLS_FILE, WRITE_PRINTSHEET_HELPER)
}


## Write config YAML
{
  write_config_yaml(plates.bc.cst.cq)
}

## Run Perl Script

## Get Perl Output


## Ridge Plots

