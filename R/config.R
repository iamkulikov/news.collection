# Defaults, limits, and shared UI constants (env-backed fields can be added later)
# Topic lists: see R/topics.R (`topic_choices`).

# `country_choices` is defined in R/countries.R (must be sourced before this file).

default_news_count <- function() 15L

news_count_limits <- function() {
  list(min = 5L, max = 50L)
}

default_date_range <- function() {
  end <- Sys.Date()
  start <- seq(from = end, length.out = 2, by = "-6 months")[2]
  c(start = start, end = end)
}

max_followup_lines <- 10L
max_followup_chars <- 200L
