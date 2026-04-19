# Parse and validate user follow-up topic lines (see plan: `;` or newline-separated).

#' Split raw textarea content into normalized topic strings.
#'
#' Splits on semicolons and line breaks; trims; collapses internal whitespace;
#' drops empty segments; removes duplicate strings (first occurrence kept).
#' @param text Character scalar from `textAreaInput` (may be NULL or "").
#' @return Character vector of topics (possibly empty).
parse_followup_text <- function(text) {
  if (is.null(text)) {
    return(character())
  }
  text <- as.character(text)
  if (!length(text)) {
    return(character())
  }
  text <- paste(text, collapse = "\n")
  if (!nzchar(trimws(text))) {
    return(character())
  }
  parts <- unlist(strsplit(text, split = "[;\r\n]+", perl = TRUE))
  parts <- trimws(parts)
  parts <- gsub("\\s+", " ", parts)
  parts <- parts[nzchar(parts)]
  if (!length(parts)) {
    return(character())
  }
  dup <- duplicated(parts)
  parts[!dup]
}

#' Validate follow-up topic list against configured limits.
#'
#' @param items Character vector from [parse_followup_text].
#' @param max_count Maximum number of topics (default: `max_followup_lines` from config).
#' @param max_chars Maximum characters per topic (default: `max_followup_chars` from config).
#' @return List: `ok` (logical), `errors` (character vector of user-facing messages).
validate_followup_topics <- function(items,
                                     max_count = max_followup_lines,
                                     max_chars = max_followup_chars) {
  errors <- character()
  n <- length(items)
  if (n > max_count) {
    errors <- c(
      errors,
      sprintf("Слишком много тем (%d). Максимум — %d.", n, max_count)
    )
  }
  too_long <- which(nchar(items) > max_chars)
  if (length(too_long)) {
    errors <- c(
      errors,
      sprintf(
        "Тема(ы) № %s длиннее %d символов (сократите или разбейте).",
        paste(too_long, collapse = ", "),
        max_chars
      )
    )
  }
  list(ok = length(errors) == 0L, errors = errors)
}

#' When follow-up is enabled: parse, require at least one topic, validate limits.
#'
#' When disabled: returns empty topics and `ok = TRUE`.
#' @param enabled Logical from checkbox.
#' @param raw_text Raw string from `textAreaInput`.
#' @return List: `ok`, `topics` (character), `errors` (character; empty if ok).
process_followup_input <- function(enabled, raw_text) {
  if (!isTRUE(enabled)) {
    return(list(ok = TRUE, topics = character(), errors = character()))
  }
  items <- parse_followup_text(raw_text)
  if (!length(items)) {
    return(list(
      ok = FALSE,
      topics = character(),
      errors = "Введите хотя бы одну follow-up тему или отключите «Include follow-up topics»."
    ))
  }
  v <- validate_followup_topics(items)
  if (!v$ok) {
    return(list(ok = FALSE, topics = items, errors = v$errors))
  }
  list(ok = TRUE, topics = items, errors = character())
}
