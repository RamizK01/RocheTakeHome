######################################################
### Question 2: ADAM ADSL creation using {admiral} ###
######################################################

# Author : Ramiz Khan
# Date   : February 11, 2026

# Create log file for output
source('utils.R')
log_file <- start_log(log_dir = 'question_1_sdtm', prefix = 'q1_log')

### Libraries & Pre-Processing ###
message('Loading in Libraries and Data')
library(admiral)
library(pharmaversesdtm)
library(dplyr, warn.conflicts = FALSE)
library(lubridate)
library(stringr)

dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae 

dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
lb <- convert_blanks_to_na(lb)

adsl <- dm |>
  select(-DOMAIN)

# Check to ensure ADSL is ORPP (One row per patient)
stopifnot(nrow(adsl) == length(unique(adsl$USUBJID)))

adsl <- adsl |>
  mutate(
    AGEGR9N = case_when(
      AGE < 18 ~ 1,
      AGE <= 50 ~ 2,
      TRUE ~ 3
    ),
    AGEGR9 = c('<18', '18 - 50', '>50')[AGEGR9N]
  ) 

ex_dtm <- ex |>
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = 'EXST'
  )

adsl <- adsl |>
  derive_vars_merged(
    dataset_add = ex_dtm,
    # Add filters to ensure that valid start date is present and that the requirements
    # are met as per the note written in the assignment
    # no need for "contains" placebo since EXTRT is only coded as either PLACEBO or the IP
    # check if flag for imputation not equal to H, then do not derive population flag
    filter_add = !is.na(EXSTDTC) & (EXDOSE > 0 | (EXDOSE == 0 & EXTRT == 'PLACEBO') & EXSTTMF == 'H'), 
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  )
  
