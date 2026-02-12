###########################################
### Question 3: Creating Visualizations ###
###########################################

# Author : Ramiz Khan
# Date   : February 11, 2026

# Create log file for output
source('utils.R')
log_file <- start_log(log_dir = 'question_3_tlg/visualizations', prefix = 'q3_plots_log')

### Libraries & Pre-Processing ###
message('Loading in Libraries and Data')
library(pharmaverseadam)
library(ggplot2)
library(dplyr)

adae <- pharmaverseadam::adae

### SEVERITY BAR PLOT ###
severity_plot <- adae |>
  ggplot(aes(x = ACTARM, fill = AESEV)) +
  geom_bar() +
  labs(title = 'AE severity distribution by treatment',
       x = 'Treatment Arm',
       y = 'Count of AEs')

ggsave(
  filename = file.path("question_3_tlg/visualizations", paste0("severity_plot", timestamp, ".png")),
  plot = severity_plot,
  width = 8,
  height = 6,
  dpi = 300
)


### TOP 10 COMMON AEs ###
num_pts <- n_distinct(adae$USUBJID)

# First summarise top AEs 
ae_sum <- adae |>
  # First remove any AETERMS that show twice for the same pt 
  group_by(USUBJID) |>
  distinct(AETERM) |>
  ungroup() |>
  # Now group by AETERM to find true count in pt pop
  group_by(AETERM) |>
  summarise(
    count = n(),
    .groups = 'drop'
  ) |>
  mutate(percentage = count / num_pts) |>
  arrange(desc(count)) |>
  head(10) # Take top 10

# Create binomial conf intervals based on counts
ci_results <- binom::binom.confint(
  x = ae_sum$count,
  n = num_pts,
  methods = "exact"  # Clopper-Pearson method
)

# add conf intervals to dataframe and convert to pcts
ae_sum <- ae_sum |> 
  bind_cols(ci_results |> select(lower, upper)) |>
  mutate(across(c(percentage, lower, upper), ~ as.numeric(.x) * 100))
  
# Create plot 
freq_plot <- ae_sum |>
  # factorize aeterm so that it displays descending order in plot
  mutate(AETERM = forcats::fct_reorder(AETERM, percentage)) |>
  ggplot(aes(x = percentage, y = AETERM)) +
  # add upper and lower conf interval error bars
  geom_errorbar(
    aes(xmin = lower, xmax = upper),
    width = 0.2,
    linewidth = 0.8,
    color = "black",
    orientation = 'y'
  ) +
  geom_point(size = 3, color = "black") +
  labs(
    title = "Top 10 Most Frequent Adverse Events",
    subtitle = paste0("n = ", num_pts, " subjects; 95% Clopper-Pearson CIs"),
    x = "Percentage of Patients (%)",
    y = NULL
  )

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

ggsave(
  filename = file.path("question_3_tlg/visualizations", paste0("freq_plot_", timestamp, ".png")),
  plot = freq_plot,
  width = 8,
  height = 6,
  dpi = 300
)

stop_log()
