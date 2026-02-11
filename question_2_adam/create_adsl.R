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
library(tidyverse)

pharmaversesdtm::dm
pharmaversesdtm::vs
pharmaversesdtm::ex
pharmaversesdtm::ds
pharmaversesdtm::ae 