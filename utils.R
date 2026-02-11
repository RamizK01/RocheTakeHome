# Function to create log files
start_log <- function(log_path, append = FALSE) {
  
  # Create directory if it doesn't exist
  dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
  
  # Open connections
  sink(log_path, append = append, split = TRUE)
  sink(log_path, append = append, type = "message")
  
  # Add header
  cat("\n==============================\n")
  cat("Log started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("==============================\n\n")
  
  # Ensure sinks close on exit
  assign(".log_active", TRUE, envir = .GlobalEnv)
}

stop_log <- function() {
  if (exists(".log_active", envir = .GlobalEnv)) {
    cat("\n==============================\n")
    cat("Log ended:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
    cat("==============================\n\n")
    
    sink(type = "message")
    sink()
    
    rm(".log_active", envir = .GlobalEnv)
  }
}
