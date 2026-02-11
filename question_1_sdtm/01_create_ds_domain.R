############################################################
### Question 1: SDTM DS Domain Creation using {sdtm.oak} ###
############################################################

# Author : Ramiz Khan
# Date   : February 9, 2026

### Libraries & Pre-Processing ###
message('Loading in Libraries and Data')
library(sdtm.oak)
library(pharmaverseraw)
library(pharmaversesdtm)
library(tidyverse)

# Load in raw data
raw_ds <- pharmaverseraw::ds_raw

# Create CT dataframe (Controlled Terminology)
ct <- read.csv('question_1_sdtm/sdtm_ct.csv')

# Create oak_id vars
message('Pre-processing raw disposition data')
raw_ds <- raw_ds |>
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "raw_ds"
  )

# Create ds object and map DSTERM
message('Begin mapping DS columns')
ds <- assign_no_ct(
  raw_dat = raw_ds,
  raw_var = 'IT.DSTERM',
  tgt_var = 'DSTERM'
  ) |>
  assign_no_ct(
    raw_dat = raw_ds,
    raw_var = 'OTHERSP',
    tgt_var = 'DSTERM'
    ) |>
  # Map DSDECOD
  assign_ct(
    raw_dat = raw_ds,
    raw_var = 'IT.DSDECOD',
    tgt_var = 'DSDECOD',
    ct_spec = ct,
    ct_clst = 'C66727' # Use CT for DSDECOD as per CDISC standards
    ) |>
  assign_no_ct(
    raw_dat = raw_ds,
    raw_var = 'OTHERSP', # For events that dont have a DSDECOD term, fill with OTHERSP term
    tgt_var = 'DSDECOD'
  ) |>
  # Create DSSDTC
  assign_datetime(
    raw_dat = raw_ds,
    raw_var = 'IT.DSSTDAT',
    tgt_var = 'DSSTDTC',
    raw_fmt = 'm-d-y', 
  ) |>
  # Create DSDTC
  assign_datetime(
    raw_dat = raw_ds,
    raw_var = c('DSDTCOL', 'DSTMCOL'),
    tgt_var = 'DSDTC',
    raw_fmt = c('m-d-y', 'H:M'),
  ) |>
  # Create VISIT
  assign_no_ct(
    raw_dat = raw_ds,
    raw_var = 'INSTANCE',
    tgt_var = 'VISIT'
  ) |>
  # Map VISITNUM
  assign_ct(
    raw_dat = raw_ds,
    raw_var = 'INSTANCE',
    tgt_var = 'VISITNUM',
    ct_spec = ct,
    ct_clst = 'VISITNUM' # Use CT for VISITNUM mapping
  ) 

# Create df with flags for DSCAT mapping 
dscat_map <- raw_ds |>
  mutate(DSCAT = case_when(
    IT.DSDECOD == 'Randomized' ~ 'PROTOCOL MILESTONE',
    !is.na(OTHERSP) ~ 'OTHER EVENT',
    TRUE ~ 'DISPOSITION EVENT'
  )) |>
  select(oak_id, DSCAT)
  

dm <- pharmaversesdtm::dm

ds <- ds |>
  mutate(
    STUDYID = raw_ds$STUDY,
    DOMAIN = 'DS',
    USUBJID = paste(gsub("\\D", "", STUDYID), patient_number, sep = '-'),
    DSDECOD = toupper(DSDECOD),
    VISITNUM = if_else(
      stringr::str_detect(VISITNUM, "^[0-9]+$"),
      VISITNUM,
      NA_character_
    )
  ) |>
  inner_join(dscat_map, by = 'oak_id') |>
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID", "DSSTDTC", 'DSDTC')
  ) |>
  derive_study_day(
    dm_domain = dm,
    tgdt = "DSSTDTC",
    refdt = "RFXSTDTC",
    study_day_var = "DSSTDY"
  ) |>
  select(STUDYID, DOMAIN, USUBJID, DSSEQ, DSTERM, DSDECOD, DSCAT, VISITNUM, VISIT, DSDTC, DSSTDTC, DSSTDY)


required_cols <- c(
  "STUDYID", "DOMAIN", "USUBJID", "DSSEQ", "DSTERM",
  "DSDECOD", "DSCAT", "VISITNUM", "VISIT",
  "DSDTC", "DSSTDTC", "DSSTDY"
)

# Check columns exist
missing_cols <- setdiff(required_cols, names(ds))

if (length(missing_cols) > 0) {
  stop(
    paste0(
      "The following required columns are missing from ds: ",
      paste(missing_cols, collapse = ", ")
    )
  )
}

# Check row counts match
if (nrow(ds_raw) != nrow(ds)) {
  stop(
    paste0(
      "Row count mismatch: ds_raw has ",
      nrow(ds_raw),
      " rows; ds has ",
      nrow(ds),
      " rows."
    )
  )
}

message("All required columns exist and row counts match.")
  