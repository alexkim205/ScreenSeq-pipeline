# parameters.R 
## requires(yaml)

list.of.packages <- c("yaml","rlist","crayon","dplyr")

#' Read a yaml file
#'
#' \code{read_parameters} reads a yaml file and exports parameters into global namespace.
#' 
#' The following parameters are exported into the global namespace:
#' \itemize{
#'   \item \code{run}
#'   \item \code{time_stamp}
#'   \item \code{days}
#'   \item \code{replicates}
#'   \item \code{UMI}
#'   \item \code{SNP}
#'   \item \code{well_alpha}
#'   \item \code{well_numer}
#'   \item \code{constructs_map_path}
#'   \item \code{constructs_maps}
#'   \item \code{barcode_maps_path}
#'   \item \code{barcode_maps}
#'   \item \code{plate_ids}
#'   \item \code{cell_quals_path}
#'   \item \code{cell_quals}
#'   \item \code{genes_l}
#'   \item \code{yaml_version}
#'   \item \code{output_path}
#'   \item \code{doS1}
#'   \item \code{SAM_location}
#'   \item \code{SAM_name_base}
#'   \item \code{fastq_dir}
#'   \item \code{R1}
#'   \item \code{R2}
#'   \item \code{doS2}
#'   \item \code{s2_result_path}
#'   \item \code{s2_result}
#'   \item \code{minimal_MAPQ}
#'   \item \code{insert_len_min}
#'   \item \code{insert_len_max}
#'   \item \code{amplicon_size_tolerance}
#'   \item \code{UMInoSNPpattern}
#'   \item \code{SNPnoUMIpattern}
#'   \item \code{T2_small}
#'   \item \code{MINflankLength}
#'   \item \code{DEBUG}
#'   \item \code{use_existing_sorted_SAM}
#'   \item \code{leave_SAM}
#'   \item \code{TryRevComp}
#'   \item \code{output_yaml}
#' }
#'
#' @param yaml_f A file path to read plate yaml from
#' @return NA
read_parameters <- function(yaml_f) {
  
  yaml_data <- read_yaml(yaml_f)
  
  ##########################
  # Identifying Parameters #
  ##########################
  
  ## id
  run <<- yaml_data$id$run
  time_stamp <<- yaml_data$id$timestamp
  #pools <- c(1:7)
  days <<- yaml_data$id$day
  replicates <<- yaml_data$id$replicate
  
  ## experiment
  UMI <<- yaml_data$experiment$UMI
  SNP <<- yaml_data$experiment$SNP
  well_alpha <<- LETTERS[1:yaml_data$experiment$well_alpha]
  well_numer <<- c(1:yaml_data$experiment$well_numer)
  
  ## data
  ### Constructs/Perturbations
  constructs_map_path <<- yaml_data$data$perturbation$path
  constructs_maps <<- yaml_data$data$perturbation$map_basename
  ### Barcodes
  barcode_maps_path <<- yaml_data$data$barcode_map$path
  barcode_maps <<- yaml_data$data$barcode_map$map_basename
  ### Plate identifiers ~ Don't edit
  plate_ids <<- paste0(constructs_maps,"_",days,"_",replicates)
  ### Cell Qualities
  cell_quals_path <<- yaml_data$data$cell_viabilities$path
  cell_quals <<- paste0(time_stamp, "_", plate_ids, "_cellqual")
  ## genes
  ### temporary solution until I figure out where these genes are coming from
  genes_l <<- yaml_data$data$genes
  
  ########################
  # Secondary Parameters #
  ########################
  
  ## YAML Version
  yaml_version <<- yaml_data$version
  
  output_path <<- yaml_data$output_path
  
  ## S1 - alignment
  doS1 <<- yaml_data$S1$doS1
  SAM_location <<- yaml_data$S1$SAM$path
  SAM_name_base <<- yaml_data$S1$SAM$basename
  fastq_dir <<- yaml_data$S1$FASTQ$path
  R1 <<- yaml_data$S1$FASTQ$R1
  R2 <<- yaml_data$S1$FASTQ$R2
  reference <<- yaml_data$S1$FASTQ$reference
  
  ## S2 - count
  doS2 <<- yaml_data$S2$doS2
  ### step 2 output
  s2_result_path <<- yaml_data$S2$count_output$path
  s2_result <<- yaml_data$S2$count_output$result
  minimal_MAPQ <<- yaml_data$S2$minimal_MAPQ
  ### global limits on insert length  (for sanity)
  insert_len_min <<- yaml_data$S2$insert_len_min
  insert_len_max <<- yaml_data$S2$insert_len_max
  ### amplicon_size +/- this is allowed:
  amplicon_size_tolerance <<- yaml_data$S2$amplicon_size_tolerance
  #~ umiPattern <- "A11 A*"
  UMInoSNPpattern <<- yaml_data$S2$UMInoSNPpattern
  SNPnoUMIpattern <<- yaml_data$S2$SNPnoUMIpattern
  #~ ignore_T2_small <<- "CGTGGAATCGCT"
  #~ T2_small <- "TCGCTAAAACG"
  T2_small <<- yaml_data$S2$T2_small
  MINflankLength <<- yaml_data$S2$MINflankLength
  
  ## Diagnostics
  DEBUG <<- yaml_data$diagnostics$DEBUG
  use_existing_sorted_SAM <<- yaml_data$diagnostics$use_existing_sorted_SAM
  leave_SAM <<- yaml_data$diagnostics$leave_SAM
  TryRevComp <<- yaml_data$diagnostics$TryRevComp
  output_yaml <<- yaml_data$diagnostics$output_yaml
  
}

#' Checks arguments
#'
#' \code{read_arguments} checks if the local library path and the plate yaml
#' file was supplied.
#'
#' @param args A vector of arguments passed in via Rscript
#' @return A list of the local library path and the plate yaml file.
read_arguments <- function(args) {
  
  manual <- "Usage: \n\t/path/to/main.R [R_LIBS_USER] [plate_yaml_file]\t/path/to/main.R [plate_yaml_file]"
  libraries <- "Error: required packages were not installed. See usage below for option to pass in a local library."
  
  if (length(args)==0) {
    stop(manual, call.=FALSE)
  } else if (length(args)==1) {
    # try default library
    new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
    if(length(new.packages)) {
      stop(paste(libraries,manual,sep="\n"), call.=FALSE)
    } else {
      return(list(NULL, args[2]))
    }
    stop(manual, call.=FALSE)
  } else if (length(args)==2) {
    # R local lib, plate yaml file
    return(list(args[1], args[2]))
  }
  print(args)
  
}

#' Loads packages
#'
#' \code{load_packages} loads the packages in the vector defined at the top of the parameters.R file.
#'
#' @param local_lib A path to a local R library folder
#' @return NA
load_packages <- function(local_lib) {
  for (pkg in list.of.packages) {
    cat(paste0("Loaded ", pkg, "\n"))
    library(pkg, character.only=TRUE, lib.loc = local_lib)
  }
}
