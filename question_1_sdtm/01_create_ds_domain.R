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

# Load in CT (Controlled Terminology)
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
  tgt_var = 'DSTERM',
  id_vars = oak_id_vars()
)

# add STUDYID, DOMAIN, and create USUBJID
ds <- assign_no_ct(
  raw_dataset = ds_raw,
  raw_var = "STUDYID",
  tgt_var = "STUDYID",
  id_vars = oak_id_vars) |>
  mutate(DOMAIN = "DS",
         USUBJID = paste(STUDYID, INVID, PATNUM, sep = "-"))
