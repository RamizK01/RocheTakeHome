start_log <- function(log_dir = ".", prefix = "log", append = FALSE) {
  # Ensure directory exists
  dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Create timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Full log file path
  log_path <- file.path(log_dir, paste0(prefix, "_", timestamp, ".txt"))
  
  # Open a file connection
  log_conn <- file(log_path, open = if(append) "a" else "w")
  
  # Open sinks for output and messages/warnings
  sink(log_conn, split = TRUE)
  sink(log_conn, type = "message")
  
  # Header
  cat("\n==============================\n")
  cat("Log started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("==============================\n\n")
  
  # Store both the path and connection in global environment
  assign(".log_active", log_path, envir = .GlobalEnv)
  assign(".log_conn", log_conn, envir = .GlobalEnv)
  
  return(log_path)
}

# To stop logging later:
stop_log <- function() {
  sink(type = "message")
  sink()
  if(exists(".log_conn", envir = .GlobalEnv)) {
    close(get(".log_conn", envir = .GlobalEnv))
    rm(.log_conn, envir = .GlobalEnv)
  }
}

save_rds <- function(object, save_dir = ".", prefix = "object") {
  # Ensure directory exists
  dir.create(save_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Create timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Full file path
  file_path <- file.path(save_dir, paste0(prefix, "_", timestamp, ".Rds"))
  
  # Save the object
  saveRDS(object, file_path)
  
  cat("Saved R object to:", file_path, "\n")
  return(file_path)
}