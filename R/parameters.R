library(yaml)

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
  # cell_quals <- paste0(time_stamp, "_", plate_ids, "_cellqual.xlsx")
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

