# Sovereign risk news — Shiny entry point
# Dependencies: shiny, bslib

library(shiny)
library(bslib)
library(jsonlite)

source("R/countries.R", local = FALSE)
source("R/topics.R", local = FALSE)
source("R/config.R", local = FALSE)
source("R/followup.R", local = FALSE)
source("R/app_ui.R", local = FALSE)
source("R/app_server.R", local = FALSE)

shinyApp(ui = app_ui, server = app_server)
