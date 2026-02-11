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