# Six thematic blocks — must match the base prompt (macro through IFI/research).
# Shiny shows `names` in the UI and passes `values` to input$topics (stable ids for prompts/JSON).

topic_choices <- c(
  "Macroeconomics" = "macro",
  "Budget & fiscal policy" = "budget",
  "Public sector & implicit liabilities" = "public_sector",
  "External position" = "external",
  "Institutions, human capital & cross-border relations" = "institutions",
  "Economic research, Article IV IMF & IFI country reviews" = "research_ifis"
)

# Values passed to the server / prompts (same order as `topic_choices`).
all_topic_ids <- unname(topic_choices)
