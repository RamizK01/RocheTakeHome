############################################################
### Question 1: SDTM DS Domain Creation using {sdtm.oak} ###
############################################################

# Author : Ramiz Khan
# Date   : February 9, 2026

# Libraries
library(sdtm.oak)
library(pharmaverseraw)
library(dplyr)

# Load in raw data
raw_dm <- pharmaverseraw::ds_raw

# Load in CT (Controlled Terminology)
ct <- read.csv('question_1/sdtm_ct.csv')