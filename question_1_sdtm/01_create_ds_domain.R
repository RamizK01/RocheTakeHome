############################################################
### Question 1: SDTM DS Domain Creation using {sdtm.oak} ###
############################################################

# Author : Ramiz Khan
# Date   : February 9, 2026

### Libraries & Pre-Processing ###
library(sdtm.oak)
library(pharmaverseraw)
library(tidyverse)

# Load in raw data
raw_ds <- pharmaverseraw::ds_raw

# Create CT dataframe (Controlled Terminology)
ct <- read.csv('question_1_sdtm/sdtm_ct.csv')

# Create oak_id vars
raw_ds <- raw_ds |>
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "raw_ds"
  )

# Create ds object and map DSTERM
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
  )
