library(data.table)
library(rlist)

source("parameters.R")

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

create_constructs <- function(tgene_f, tgene_fo) {
  
  tgene_df <- read_excel(tgene_f)
  
  # tgene_df %>% 
  #   group_by(Symbol) %>% 
  #   mutate(construct=if(n()>1) {paste0(Symbol, "_", Region, "_", row_number())}
  #          else paste0(Symbol, "_", Region)) 
  
  hash <- list()
  tgene_df$`Construct ID` <- 0
  
  for (row in 1:nrow(tgene_df)) {
    x <- tgene_df$Symbol[row]
    if (x %in% names(hash)) {hash[[x]] <- hash[[x]] + 1} 
    else {hash[[x]] <- 1}
    tgene_df$`Construct ID`[row] <- paste0(x, "_", hash[[x]])
  }
  
  if (WRITE_CONSTRUCT_FILE) {
    write_xlsx(tgene_df, tgene_fo)
  }
  return(tgene_df)
  
}

create_plates <- function(plate_ids, barcode_maps) {
  
  barcode_maps_f <- paste0(barcode_maps_path, barcode_maps, ".xlsx")
  preset_bc_maps = c("P1", "P1a", "P2", "P3", "P4")
  
  plates <- sapply(plate_ids, function(x) NULL)
  
  for (plate_i in 1:length(plate_ids)) {
    
    barcodes_for_plate <- read_excel(barcode_maps_f[plate_i], col_names=FALSE)$X__1
    plates[[plate_ids[plate_i]]] <- 
      create_new_plate_from_list(plates[[plate_ids[plate_i]]], 
                           well_alpha, well_numer, 
                           "barcode", barcodes_for_plate)
      # traverse_into_plate_wells(plates[[plate_ids[plate_i]]], "barcode", barcodes_for_plate)
    
    # offset <- offsets[match(barcode_maps[plate_i], barcode_maps)]
    # temp_plate <- create_barcodes(well_alpha, well_numer, offset)
    # plates[[plate_ids[plate_i]]] <- temp_plate
  }
  return(plates)
  
}

create_new_plate_from_list <- function(plate, well_alpha, well_numer, id, list) {
  # create new plate list from list of barcodes/target_genes
  
  properties_per_well <- c("barcode", "target_gene", "cell_quality")
    
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

# DONT USE FOR NOW
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

add_gene_id <- function(plates, target_genes_list) {
  
  temp_plates <- plates
  for (plate in seq_along(plates)) {
    temp_plates[[plate]] <- traverse_into_plate_wells(temp_plates[[plate]], "target_gene", target_genes_list)
  }
  return(temp_plates)
  
}

write_wells_info <- function(output_dir, plates_list, WRITE_WELLS_FILE, WRITE_PRINTSHEET_HELPER) {
  
  # Write Plate Information to YAML
  if (WRITE_WELLS_FILE) {
    
    yaml_fo <- file.path(output_dir, 'wells_info.yaml')
    list.save(plates_list, yaml_fo)
    
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
      
      rmarkdown::render("plate_info_template_v2.Rmd", output_file = report_fo,
                        params = params,
                        envir = new.env())
      
    }
  }
}

