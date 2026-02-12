##########################################
### Question 3: Creating Summary Table ###
##########################################

# Author : Ramiz Khan
# Date   : February 11, 2026


# Create log file for output
source('utils.R')
log_file <- start_log(log_dir = 'question_3_tlg/summary_table', prefix = 'q3_viz_log')

### Libraries & Pre-Processing ###
message('Loading in Libraries and Data')
library(pharmaverseadam)
library(gtsummary)

adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

adae <- adae |>
  filter(
    # Question does not state for the safety population but it is common practice
    SAFFL == 'Y',
    # Filter treatment emergent AEs
    TRTEMFL == 'Y'
  )

tbl <- adae |>
  tbl_hierarchical(
    variables = c(AESOC, AETERM),
    by = ACTARM,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,
    label = "..ard_hierarchical_overall.." ~ "Treatment Emergent AEs"
  ) |>
  sort_hierarchical(sort = everything() ~ "descending")

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
file_name <- paste0("adae_summary_", timestamp, ".pdf")

# Convert gtsummary table to gt object
gt_tbl <- as_gt(tbl)

# Save as PDF
gt::gtsave(gt_tbl, filename = file_name, path = 'question_3_tlg/summary_table/')

stop_log()
