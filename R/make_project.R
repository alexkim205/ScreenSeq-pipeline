
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
#'   \item \{project_run_name\}/
#'   \itemize{
#'     \item barcodes/
#'     \item cell_viabilities/
#'     \itemize{
#'       \item \{project_run_name\}_P\{\code{pools[1]}\}/
#'       \item \{project_run_name\}_P\{\code{pools[2]}\}/
#'       \item ...
#'     }
#'     \item config/
#'     \item constructs/
#'     \item fastq/
#'     \itemize{
#'       \item \{project_run_name\}_P\{\code{pools[1]}\}/
#'         \itemize{
#'           \item \{project_run_name\}_P\{\code{pools[1]}\}_R1.fastq
#'           \item \{project_run_name\}_P\{\code{pools[1]}\}_R2.fastq
#'         }
#'       \item \{project_run_name\}_P\{\code{pools[2]}\}/
#'         \itemize{
#'           \item ...
#'         }
#'       \item ...
#'     }
#'     \item logs/
#'     \item output/
#'     \item sam/
#'     \itemize{
#'       \item \{project_run_name\}_P\{\code{pools[1]}\}/
#'       \item \{project_run_name\}_P\{\code{pools[2]}\}/
#'       \item ...
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
#' @param project_dir A file path 
#' @param project_run_name A string identifier for the experiment
#' @param pools A vector of pool ID's
#' @param overwrite A boolean that if true will overwrite any existing project 
#'   directory specified at \code{project_dir}
#' @return NA
make_project <- function(project_dir, pools, overwrite = TRUE) {
  # TODOO NOT DONE
  project_path <- file.path(project_dir, pools)
  output_dir <- file.path(project_dir, "output")
  dir.create(output_dir, showWarnings = FALSE)
  config_dir <- file.path(project_dir, "config")
  dir.create(config_dir, showWarnings = FALSE)
  
}