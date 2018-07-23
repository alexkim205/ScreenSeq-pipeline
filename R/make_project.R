#' Make project directory structure
#'
#' \code{traverse_into_plate_wells} traverses through a plate list and sets
#' \code{input_data} to property \code{id} for each well.
#'
#' Running this helper function will generate a project directory
#' structure given the proper parameters. The function will also copy the 
#' necessary scripts into the src folder. The entire folder hierarchy that 
#' is generated will look like this: 
#' 
#' \itemize{
#'   \item \{plate_name\}/
#'   \itemize{
#'     \item cell_viabilities/
#'     \item config/
#'     \item logs/
#'     \item outputs/
#'     \itemize{
#'       \item sam/
#'     }
#'     \item src/
#'     \itemize{
#'       \item perl/
#'       \item sh/
#'     }
#'   }
#' }
#'
#'
#' @param output_dir A file path of where the plate folder will be created
#' @param plate_name A string of the plate name
#' @param overwrite A boolean that if true will overwrite any existing project 
#'   directory specified at \code{project_dir}
#' @return The project_run_dir path
make_project <- function(output_dir, plate_name, overwrite = TRUE) {
  
  # project_dir is plate directory
  project_dir <- mkdir(output_dir, plate_name)
  
  {
    cell_viabilities_dir <- mkdir(project_dir, "cell_viability")
    config_dir <- mkdir(project_dir, "config")
    logs_dir <- mkdir(project_dir, "log")
    outputs_dir <- mkdir(project_dir, "output")
    {
      # where s1 alignments go
      sams_dir <- mkdir(outputs_dir, "sam")
    }
    # copy in scripts from helper scripts folder
    src_dir <- mkdir(project_dir, "src")
    {
      file.copy("src_help/perl", src_dir, recursive=TRUE)
      file.copy("src_help/sh", src_dir, recursive=TRUE)
    }
  }
  
  return(project_dir)
}

mkdir <- function(path, path_in_path) {
  temp_dir <- file.path(path, path_in_path)
  dir.create(temp_dir, showWarnings = FALSE)
  return(temp_dir)
}
