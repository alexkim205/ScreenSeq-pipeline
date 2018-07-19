library(data.table)
library(rlist)

#' Traverse into plate wells
#'
#' \code{traverse_into_plate_wells} traverses through a plate list and sets
#' \code{input_data} to property \code{id} for each well.
#'
#' @param plate A plate list
#' @param id A property of a well
#' @param input_data A list of values to be set
#' @return The modified plate list
traverse_into_plate_wells <- function(plate, id, input_data) {
  # Put data in
  
  temp_plate <- plate
  i <- 1
  
  #    Plate ID
  ##   Well Letter
  ###  Well Number
  #### Barcode
  #### Target Gene ID
  
  for (well_section_i in seq_along(temp_plate)) {
    for (well_i in seq_along(temp_plate[[well_section_i]])) {
      temp_plate[[well_section_i]][[well_i]][[id]] <-input_data[i]
      i <- i + 1
    }
  }
  
  return(temp_plate)
}

#' Traverse out of plate wells
#'
#' \code{traverse_outof_plate_wells} traverses through a plate list and gets
#' value at property \code{id} for each well.
#'
#' @param plate A plate list
#' @param id A property of a well
#' @return A vector of values of property \code{id} across all wells
traverse_outof_plate_wells <- function(plate, id) {
  # Get data_id out
  
  temp_plate <- plate
  temp_vector <- c()
  i <- 1
  
  #    Plate ID
  ##   Well Letter
  ###  Well Number
  #### Barcode
  #### Target Gene ID
  for (well_section_i in seq_along(plate)) {
    for (well_i in seq_along(temp_plate[[well_section_i]])) {
      temp_vector[i] <- plate[[well_section_i]][[well_i]][[id]]
      i <- i + 1
    }
  }
  
  return(temp_vector)
}

#' Get construct ids
#'
#' \code{get_constructs} reads construct file and creates unique construct id
#' column.
#'
#' @param plate_ids A vector of plate id's
#' @param constructs_f A vector of file paths to constructs .xlsx files
#' @param constructs_fo A vector of file paths to write modified constructs .xlsx files
#' @return A list of vectors of constructs
get_constructs <- function(plate_ids, constructs_f, constructs_fo, WRITE_CONSTRUCT_FILE) {
  
  temp_constructs_l <- list()
  
  for (constructs_f_1 in seq_along(constructs_f)) {
    
    constructs_df <- read_excel(constructs_f[constructs_f_1])
    constructs_df <- constructs_df %>%
      group_by(Symbol) %>%
      mutate(construct=if(n()>1) {paste0(Symbol, "_", Region, "_", row_number())}
             else paste0(Symbol, "_", Region))
    
    temp_constructs_l[[plate_ids[constructs_f_1]]] <- constructs_df$construct
    
    if (WRITE_CONSTRUCT_FILE) {
      write_xlsx(tgene_df, tgene_fo)
    }
  }
  
  return(temp_constructs_l)
}

#' Get cell qualities
#'
#' \code{get_cell_qualities} reads multiple cell quality files and returns list of vectors
#'
#' @param plate_ids A vector of plate id's
#' @param cell_quals_f A vector of file paths to cell quality .xlsx files
#' @return A list of vectors of cell qualities
get_cell_qualities <- function(plate_ids, cell_quals_f) {
  
  temp_cell_quals_l <- list()
  
  for (cell_quals_f_1 in seq_along(cell_quals_f)) {
    cell_quals_df <- read_excel(cell_quals_f[cell_quals_f_1])
    temp_cell_quals_l[[plate_ids[cell_quals_f_1]]] <- cell_quals_df$Cell_quality
  }
  
  return(temp_cell_quals_l)
}

#' Create plates
#'
#' \code{create_plates} creates a plate list for each \code{plate_id} using
#' appropriate barcode maps.
#'
#' @param plate_ids A vector of plate id's
#' @param barcode_maps_f A vector of filepaths to barcode maps that has the same
#'   length as \code{plate_ids}.
#' @return A list of the plate lists that were created.
create_plates <- function(plate_ids, barcode_maps_f) {
  
  preset_bc_maps = c("P1", "P1a", "P2", "P3", "P4")
  
  plates <- sapply(plate_ids, function(x) NULL)
  
  for (plate_i in 1:length(plate_ids)) {
    
    barcodes_for_plate <- read_excel(barcode_maps_f[plate_i], col_names=FALSE)$X__1
    plates[[plate_ids[plate_i]]] <- create_new_plate_from_list(well_alpha, well_numer, "barcode", barcodes_for_plate)
  }
  return(plates)
  
}

#' Create new plate from a list
#'
#' \code{create_new_plate_from_list} creates a new plate list using specific property as
#' guideline.
#'
#' @param well_alpha A vector of letters from the alphabet corresponding to
#'   barcode plate rows
#' @param well_numer A vector of numbers corresponding to barcode plate columns
#' @param id The id of the property of the list you are creating plate from
#' @param list The list of values of specific property of well
#' @return A plate list
create_new_plate_from_list <- function(well_alpha, well_numer, id, list) {
  # create new plate list from list of barcodes/construct/cell_quality
  
  properties_per_well <- c("barcode", "construct", "cell_quality")
  
  temp_plate <- sapply(well_alpha,function(x) NULL)
  i <- 1
  
  for (well_section_i in seq_along(temp_plate)) {
    temp_plate[[well_section_i]] <- sapply(well_numer,function(x) NULL)
    for (well_i in seq_along(temp_plate[[well_section_i]])) {
      temp_plate[[well_section_i]][[well_i]] <- sapply(properties_per_well, function(x) NULL)
      temp_plate[[well_section_i]][[well_i]][[id]] <- list[i]
      i <- i + 1
    }
  }
  
  return(temp_plate)
}

#' Add the same property vector to a list of plates
#'
#' \code{add_list_to_plates} adds the same property list to all plates in the
#' given list of plates.
#'
#' @param plates A list of plates
#' @param id The id of the property of the list you are adding
#' @param list The list of values of specific property of well
#' @return A plate list with added property for each well
add_list_to_plates <- function(plates, id, list) {
  
  temp_plates <- plates
  for (plate in seq_along(plates)) {
    temp_plates[[plate]] <- traverse_into_plate_wells(temp_plates[[plate]], id, list)
  }
  return(temp_plates)
  
}

#' Add a list of property vectors to a list of plates
#'
#' \code{add_list_to_plates} adds list of property vectors to respective plates in the
#' given list of plates.
#'
#' @param plates A list of plates
#' @param id The id of the property of the list you are adding
#' @param lists The list of vectors of specific property of well
#' @return A plate list with added property for each well
add_lists_to_plates <- function(plates, id, lists) {
  
  temp_plates <- plates
  for (plate in seq_along(plates)) {
    temp_plates[[plate]] <- traverse_into_plate_wells(temp_plates[[plate]], id, lists[[plate]])
  }
  return(temp_plates)
  
}

# DONT USE FOR NOW, should be renamed to generate_barcodes
create_barcodes_old <- function(well_alpha, well_numer, offset = 0, divider = 3) {
  
  barcode_in_df <- read_excel(barcodes_f)
  fw <- barcode_in_df$`fw_BC`
  rv <- fw
  section <- length(fw) / 3
  
  starts <- fw[seq(1, length(fw), section)]
  
  wells <- sapply(well_alpha,function(x) NULL)
  
  offset_wrap <- function(a, o) {
    shift_temp <- a[c(1:o)]
    a <- shift(a, o, type="lead")
    a[c((length(a)-o+1):length(a))] <- shift_temp
    return(a)
  }
  
  #    Plate ID
  ##   Well Letter
  ###  Well Number
  #### Barcode
  #### Target Gene ID
  for (sec in 1:divider) {
    s <- (sec - 1) * section + 1
    e <- sec * section
    fw_temp <- fw[s:e]
    for (secsec in 1:divider) {
      s <- (secsec - 1) * section + 1
      e <- secsec * section
      section_i <- (sec - 1) * divider + secsec
      rv_temp <- rv[s:e]
      # offset
      rv_temp <- offset_wrap(rv_temp, offset)
      for (secsecsec in 1:section) {
        final_barcode <- paste0(fw_temp[secsecsec], "_", rv_temp[secsecsec])
        if (section_i <= length(well_alpha)) {
          wells[[well_alpha[section_i]]][[secsecsec]] <- sapply(c("barcode", "target_gene"),function(x) NULL)
          wells[[well_alpha[section_i]]][[secsecsec]][["barcode"]] <- final_barcode
        }
      }
    }
  }
  
  return(wells)
}

#' Write list of plates to yaml file
#'
#' \code{write_wells_info} writes per well information to a easily readable yaml file.
#'
#' @param output_dir A path to directory to output files to
#' @param plates A list of plate lists that carries all the well information
#' @param WRITE_WELLS_FILE If \code{TRUE}, write .yaml file, otherwise don't
#' @param WRITE_PRINTSHEET_HELPER If \code{TRUE}, create pipetting helper file,
#'   otherwise don't
#' @return NA
write_wells_info <- function(output_dir, plates, WRITE_WELLS_FILE, WRITE_PRINTSHEET_HELPER) {
  
  # Write Plate Information to YAML
  if (WRITE_WELLS_FILE) {
    
    yaml_fo <- file.path(output_dir, 'wells_info.yaml')
    list.save(plates, yaml_fo)
    
  }
  # Write HTML Supplementary .Rmd
  if (WRITE_PRINTSHEET_HELPER) {
    
    # For each plate, print Rmd and .xlsx
    for (plate_i in seq_along(plates)) {
      
      plate_id <- plate_ids[plate_i]
      barcode_by_plate <- barcode_maps[plate_i]
      report_fo <- file.path(output_dir, paste0(plate_id, '_plate_info.Rmd'))
      barcode_fo <- file.path(output_dir, paste0(plate_id, "_", barcode_by_plate, "_map.xlsx"))
      
      params <- list(plate = plates[[plate_id]],
                     traverse_out_fn = traverse_outof_plate_wells)
      
      # rmarkdown::render("plate_info_template_v2.Rmd", output_file = report_fo,
      #                   params = params,
      #                   envir = new.env())
      
    }
  }
}

