######################################################
### Question 2: ADAM ADSL creation using {admiral} ###
######################################################

# Author : Ramiz Khan
# Date   : February 11, 2026

# Create log file for output
source('utils.R')
log_file <- start_log(log_dir = 'question_2_adam', prefix = 'q2_log')

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

message('Create ADSL')
adsl <- dm |>
  select(-DOMAIN)

# Check to ensure ADSL is ORPP (One row per patient)
stopifnot(nrow(adsl) == length(unique(adsl$USUBJID)))

message('Mapping basic vars')
adsl <- adsl |>
  mutate(
    AGEGR9N = case_when(
      AGE < 18 ~ 1,
      AGE <= 50 ~ 2,
      TRUE ~ 3
    ),
    AGEGR9 = c('<18', '18 - 50', '>50')[AGEGR9N]
  ) 

message('Deriving Exposure Start/End')
ex_dtm <- ex |>
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = 'EXST'
  ) |>
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    time_imputation = "last"
  )

adsl <- adsl |>
  derive_vars_merged(
    dataset_add = ex_dtm,
    # Add filters to ensure that valid start date is present and that the requirements
    # are met as per the note written in the assignment
    # no need for "contains" placebo since EXTRT is only coded as either PLACEBO or the IP
    # check if flag for imputation not equal to H, then do not derive population flag
    filter_add = !is.na(EXSTDTC) & (EXDOSE > 0 | (EXDOSE == 0 & EXTRT == 'PLACEBO') & EXSTTMF == 'H'), 
    # Create dt var and flag
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    # Choose first (earliest) record
    mode = "first",
    # grouping vars
    by_vars = exprs(STUDYID, USUBJID)
  ) |> 
  # While not required by the assignment, TRTEDTM is required downstream to map
  # variable LSTAVLDT 
  derive_vars_merged(
    dataset_add = ex_dtm,
    filter_add = !is.na(EXSTDTC) & (EXDOSE > 0 | (EXDOSE == 0 & EXTRT == 'PLACEBO') & EXSTTMF == 'H'),
    new_vars = exprs(TRTEDTM = EXENDTM, TRTETMF = EXENTMF),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last",
    by_vars = exprs(STUDYID, USUBJID)
  ) |>
  derive_var_merged_exist_flag(
    dataset_add = dm,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = ITTFL,
    missing_value = 'N',
    condition = (!is.na(ARM))
  ) 

message('Derive Last Alive Timepoint')
# Derive in seperate step so we can bring in TRTEDTM from adsl for the LSTAVLDT
adsl <- adsl |>
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    events = list(
      event(
        dataset_name = 'vs',
        order = exprs(VSDTC, VSSEQ),
        condition = !is.na(VSDTC) & (!is.na(VSSTRESN) & !is.na(VSSTRESC)),
        set_values_to = exprs(
          LSTAVLDT = convert_dtc_to_dt(VSDTC),
          seq = VSSEQ
        )
      ),
      event(
        dataset_name = 'ae',
        order = exprs(AESTDTC, AESEQ),
        condition = !is.na(AESTDTC),
        set_values_to = exprs(
          LSTAVLDT = convert_dtc_to_dt(AESTDTC),
          seq = AESEQ
        )
      ),
      event(
        dataset_name = 'ds',
        order = exprs(DSSTDTC, DSSEQ),
        condition = !is.na(DSSTDTC),
        set_values_to = exprs(
          LSTAVLDT = convert_dtc_to_dt(DSSTDTC),
          seq = DSSEQ
        )
      ),
      event(
        dataset_name = "adsl",
        condition = !is.na(TRTEDTM),
        set_values_to = exprs(
          LSTAVLDT = TRTEDTM,
          seq = 0
          )
      )
    ),
    source_datasets = list(vs = vs, ae = ae, ds = ds, adsl = adsl),
    tmp_event_nr_var = event_nr,
    order = exprs(LSTAVLDT, seq, event_nr),
    mode = "last",
    new_vars = exprs(LSTAVLDT)
  ) |>
    # Note that the spelling of the variable LSTAVLDT is incorrect, the programming 
    # assignment provided by roche has it listed as "LSTAVLDT" despite CDISC standards
    # having it as "LSTALVDT", ultimately i followed the assingment worksheet in naming
    # but in an actual study this is a huge data quality issue if the specs are mis-spelled
  labelled::set_variable_labels(
    AGEGR9    = "Age Group 9",
    AGEGR9N   = "Age Group 9 (N)",
    TRTSDTM   = "Datetime of First Exposure to Treatment",
    TRTSTMF   = "Time of First Exposure Imputation Flag",
    TRTEDTM   = "Datetime of Last Exposure to Treatment",
    TRTETMF   = "Time of Last Exposure Imputation Flag",
    ITTFL     = "Intent-To-Treat Population Flag",
    LSTAVLDT  = "Date Last Known Alive"
  )

# Quick QC check 
required_cols <- c(
  "AGEGR9", "AGEGR9N", "TRTSDTM", "TRTSTMF",
  "TRTEDTM", "TRTEDMF", "ITTFL", "LSTAVLDT"
)

missing_cols <- setdiff(required_cols, names(adsl))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

stopifnot(nrow(dm) == nrow(adsl))

# Finalize work and save
save_rds(adsl, save_dir = 'question_2_adam', prefix = 'ADSL')
stop_log()
  
