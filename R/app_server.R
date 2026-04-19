# Server: wiring for baseline inputs/outputs (API integration comes later)

app_server <- function(input, output, session) {
  observeEvent(input$btn_last_6m, {
    dr <- default_date_range()
    updateDateRangeInput(
      session,
      "date_range",
      start = dr[["start"]],
      end = dr[["end"]]
    )
  })

  observeEvent(input$topics_select_all, {
    req(isFALSE(input$all_topics))
    updateCheckboxGroupInput(session, "topics", selected = all_topic_ids)
  })

  observeEvent(input$topics_clear, {
    req(isFALSE(input$all_topics))
    updateCheckboxGroupInput(session, "topics", selected = character())
  })

  status <- reactiveVal("Set parameters and click “Find news”. Results are a stub until the OpenAI client is connected.")

  last_stub_payload <- reactiveVal(NULL)

  observeEvent(input$run, {
    withProgress(message = "Working…", value = 0, {
      incProgress(0.2, detail = "Validating inputs")
      country_iso3 <- input$country
      if (is.null(country_iso3) || !nzchar(country_iso3)) {
        country_iso3 <- ""
      }
      start <- input$date_range[1]
      end <- input$date_range[2]
      topics_sel <- if (isTRUE(input$all_topics)) all_topic_ids else input$topics
      follow <- process_followup_input(
        isTRUE(input$followup_enabled),
        input$followup_topics
      )

      if (identical(country_iso3, "")) {
        status("Please select a country.")
        last_stub_payload(NULL)
        incProgress(1)
        return()
      }

      if (!country_iso3_valid(country_iso3)) {
        status("Invalid country code. Choose a country from the list.")
        last_stub_payload(NULL)
        incProgress(1)
        return()
      }

      if (is.null(start) || is.null(end) || start > end) {
        status("Invalid date range.")
        last_stub_payload(NULL)
        incProgress(1)
        return()
      }

      if (!follow$ok) {
        status(paste(c("Follow-up topics:", follow$errors), collapse = "\n"))
        last_stub_payload(NULL)
        incProgress(1)
        return()
      }

      incProgress(0.4, detail = "Summarizing (stub)")
      incProgress(0.7, detail = "Building list (stub)")

      payload <- list(
        country = country_iso3,
        time_window = list(start = as.character(start), end = as.character(end)),
        all_topics = isTRUE(input$all_topics),
        topics = topics_sel,
        follow_up_enabled = isTRUE(input$followup_enabled),
        follow_up_queries = follow$topics,
        n = as.integer(input$news_count),
        note = "scaffold_stub"
      )
      last_stub_payload(payload)

      fu_line <- if (length(follow$topics)) {
        paste0(" | Follow-up: ", length(follow$topics), " topic(s)")
      } else {
        ""
      }
      status(paste0(
        "Last run: ", Sys.time(), "\n",
        "Country: ", country_iso3,
        " | Period: ", start, " → ", end,
        " | N: ", payload$n,
        " | Topics: ", if (length(topics_sel)) paste(topics_sel, collapse = ", ") else "(none)",
        fu_line
      ))

      incProgress(1, detail = "Done")
    })
  })

  output$status <- renderText({
    status()
  })

  output$results <- renderUI({
    p <- last_stub_payload()
    if (is.null(p)) {
      return(tags$p(class = "text-muted", "No run yet."))
    }
    tags$div(
      class = "p-2",
      tags$p(tags$strong("Stub result"), " — cards/table will render validated API JSON here."),
      tags$pre(
        class = "bg-light p-2 rounded small",
        jsonlite::toJSON(p, auto_unbox = TRUE, pretty = TRUE)
      )
    )
  })

  output$export_json <- downloadHandler(
    filename = function() {
      paste0("sovereign_news_stub_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json")
    },
    content = function(file) {
      p <- last_stub_payload()
      if (is.null(p)) {
        writeLines("{}", file)
        return()
      }
      writeLines(as.character(jsonlite::toJSON(p, auto_unbox = TRUE, pretty = TRUE)), file)
    }
  )
}
