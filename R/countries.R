# Country reference: ISO2/ISO3, English names from `countrycode::codelist`, plus
# normalized aliases for search (including common transliterations / shorthand).

# --- normalization ----------------------------------------------------------

#' Normalize user input for country lookup (trim, lower case, collapse spaces,
#' strip punctuation to spaces).
#'
#' @param x Character vector.
#' @return Character vector of the same length.
normalize_country_query <- function(x) {
  if (!length(x)) {
    return(character())
  }
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- trimws(x)
  x <- tolower(x)
  x <- gsub("[[:punct:]]", " ", x, perl = TRUE)
  x <- gsub("\\s+", " ", x, perl = TRUE)
  trimws(x)
}


# --- internal: build canonical table ----------------------------------------

.country_name_col <- function(cl) {
  if ("country.name.en" %in% names(cl)) {
    return("country.name.en")
  }
  if ("country.name" %in% names(cl)) {
    return("country.name")
  }
  stop("countrycode::codelist: expected country.name.en or country.name")
}


.build_country_rows <- function() {
  cl <- countrycode::codelist
  name_col <- .country_name_col(cl)
  iso2 <- cl[["iso2c"]]
  iso3 <- cl[["iso3c"]]
  nm <- cl[[name_col]]

  ok <- !is.na(iso3) & nzchar(iso3) & nchar(iso3) == 3L
  iso2 <- ifelse(ok, as.character(iso2), NA_character_)
  iso3 <- ifelse(ok, as.character(iso3), NA_character_)
  nm <- ifelse(ok, as.character(nm), NA_character_)

  ok <- ok & !is.na(nm) & nzchar(nm)
  iso2 <- iso2[ok]
  iso3 <- iso3[ok]
  nm <- nm[ok]

  dup <- duplicated(iso3)
  iso2 <- iso2[!dup]
  iso3 <- iso3[!dup]
  nm <- nm[!dup]

  data.frame(
    iso2 = iso2,
    iso3 = iso3,
    name = nm,
    stringsAsFactors = FALSE
  )
}


# alias_normalized -> iso3 (manual extensions; keys must be normalized)
.country_manual_aliases <- function() {
  c(
    "uk" = "GBR",
    "u k" = "GBR",
    "great britain" = "GBR",
    "britain" = "GBR",
    "england" = "GBR",
    "united kingdom" = "GBR",
    "usa" = "USA",
    "u s" = "USA",
    "u s a" = "USA",
    "united states" = "USA",
    "united states of america" = "USA",
    "south korea" = "KOR",
    "korea south" = "KOR",
    "north korea" = "PRK",
    "korea north" = "PRK",
    "russia" = "RUS",
    "russian federation" = "RUS",
    "россия" = "RUS",
    "российская федерация" = "RUS",
    "бразилия" = "BRA",
    "мексика" = "MEX",
    "индия" = "IND",
    "турция" = "TUR",
    "юар" = "ZAF",
    "south africa" = "ZAF",
    "türkiye" = "TUR",
    "turkiye" = "TUR",
    "ivory coast" = "CIV",
    "cote d ivoire" = "CIV",
    "czechia" = "CZE",
    "bolivia plurinational state of" = "BOL",
    "bolivia" = "BOL",
    "viet nam" = "VNM",
    "vietnam" = "VNM",
    "laos" = "LAO",
    "lao" = "LAO",
    "myanmar burma" = "MMR",
    "burma" = "MMR",
    "iran islamic republic of" = "IRN",
    "syrian arab republic" = "SYR",
    "micronesia" = "FSM",
    "moldova" = "MDA",
    "palestine" = "PSE",
    "swaziland" = "SWZ",
    "eswatini" = "SWZ"
  )
}


.country_index_env <- new.env(parent = emptyenv())

.get_country_index <- function() {
  if (exists("idx", envir = .country_index_env, inherits = FALSE)) {
    return(get("idx", envir = .country_index_env))
  }
  rows <- .build_country_rows()
  aliases <- .country_manual_aliases()
  idx <- list(
    rows = rows,
    aliases = aliases
  )
  assign("idx", idx, envir = .country_index_env)
  idx
}


# --- labels & choices for UI ------------------------------------------------

.country_row_label <- function(name, iso2, iso3) {
  iso2 <- if (!is.na(iso2) && nzchar(iso2)) iso2 else NA_character_
  if (!is.na(iso2)) {
    sprintf("%s — %s / %s", name, iso2, iso3)
  } else {
    sprintf("%s — %s", name, iso3)
  }
}


#' Human-readable label for an ISO3 code (from the index).
#'
#' @param iso3 Character scalar ISO3.
#' @return Label string, or NA_character_ if unknown.
country_label <- function(iso3) {
  iso3 <- toupper(trimws(as.character(iso3)))
  if (!nzchar(iso3)) {
    return(NA_character_)
  }
  idx <- .get_country_index()
  m <- match(iso3, idx$rows$iso3)
  if (is.na(m)) {
    return(NA_character_)
  }
  .country_row_label(idx$rows$name[m], idx$rows$iso2[m], idx$rows$iso3[m])
}


#' Named vector suitable for `selectizeInput(choices = ...)`: values are ISO3.
country_selectize_choices <- function() {
  idx <- .get_country_index()
  r <- idx$rows
  labs <- vapply(seq_len(nrow(r)), function(i) {
    .country_row_label(r$name[i], r$iso2[i], r$iso3[i])
  }, character(1))
  out <- r$iso3
  names(out) <- labs
  out
}


# --- search & resolve -------------------------------------------------------

.score_match <- function(q, iso2, iso3, name_norm) {
  if (!nzchar(q)) {
    return(0)
  }

  iso2u <- toupper(iso2)
  iso3u <- toupper(iso3)
  qu2 <- toupper(q)
  qu3 <- toupper(q)

  # ISO exact (user may type br / bra without normalization stripping)
  if (nchar(qu2) == 2L && !is.na(iso2u) && nzchar(iso2u) && qu2 == iso2u) {
    return(100L)
  }
  if (nchar(qu3) == 3L && qu3 == iso3u) {
    return(100L)
  }

  if (identical(q, name_norm)) {
    return(90L)
  }
  if (startsWith(name_norm, q)) {
    return(82L)
  }

  words <- strsplit(name_norm, " ", fixed = TRUE)[[1]]
  words <- words[nzchar(words)]
  if (length(words) && identical(q, words[1L])) {
    return(78L)
  }
  if (any(startsWith(words, q))) {
    return(72L)
  }

  if (grepl(paste0("(^| )", gsub("([.|()\\[\\]{}^$*+?|\\\\])", "\\\\\\1", q, perl = TRUE)), name_norm, perl = TRUE)) {
    return(68L)
  }

  if (grepl(q, name_norm, fixed = TRUE)) {
    return(60L)
  }

  0L
}


#' Search countries by ISO2/ISO3 fragment, English name, or known aliases.
#'
#' @param query User query string.
#' @param limit Max rows to return.
#' @return `data.frame` with columns `iso3`, `iso2`, `name`, `label`, `score`.
country_search <- function(query, limit = 20L) {
  limit <- as.integer(limit)[1L]
  if (is.na(limit) || limit < 1L) {
    limit <- 20L
  }

  idx <- .get_country_index()
  rows <- idx$rows
  aliases <- idx$aliases

  q_raw <- as.character(query)[1L]
  if (is.na(q_raw)) {
    q_raw <- ""
  }

  q <- normalize_country_query(q_raw)
  q_iso <- toupper(trimws(q_raw))

  # Map query to extra ISO3 hits from manual aliases (exact normalized key)
  alias_hits <- character()
  if (nzchar(q) && q %in% names(aliases)) {
    hit <- aliases[[q]]
    alias_hits <- unique(as.character(hit))
  }

  n <- nrow(rows)
  scores <- integer(n)
  name_norm <- vapply(rows$name, normalize_country_query, character(1))

  for (i in seq_len(n)) {
    scores[i] <- .score_match(q, rows$iso2[i], rows$iso3[i], name_norm[i])
    if (length(alias_hits) && rows$iso3[i] %in% alias_hits) {
      scores[i] <- max(scores[i], 92L)
    }

    # Direct ISO code typed with odd spacing/punctuation already normalized away —
    # compare uppercase 2/3 letter tokens to iso2/iso3
    if (scores[i] < 100L && nzchar(q_iso)) {
      if (nchar(q_iso) == 2L && !is.na(rows$iso2[i]) && q_iso == toupper(rows$iso2[i])) {
        scores[i] <- 100L
      } else if (nchar(q_iso) == 3L && q_iso == toupper(rows$iso3[i])) {
        scores[i] <- 100L
      }
    }
  }

  ord <- order(-scores, rows$name, rows$iso3)
  rows <- rows[ord, , drop = FALSE]
  scores <- scores[ord]

  keep <- scores > 0L
  rows <- rows[keep, , drop = FALSE]
  scores <- scores[keep]

  if (nrow(rows) > limit) {
    rows <- rows[seq_len(limit), , drop = FALSE]
    scores <- scores[seq_len(limit)]
  }

  labs <- vapply(seq_len(nrow(rows)), function(i) {
    .country_row_label(rows$name[i], rows$iso2[i], rows$iso3[i])
  }, character(1))

  data.frame(
    iso3 = rows$iso3,
    iso2 = rows$iso2,
    name = rows$name,
    label = labs,
    score = as.integer(scores),
    stringsAsFactors = FALSE
  )
}


#' Resolve a single ISO3 from a query using `countrycode::countrycode` and search.
#'
#' @param query Character scalar.
#' @return ISO3 code or `NA_character_`.
country_resolve <- function(query) {
  q_raw <- as.character(query)[1L]
  if (is.na(q_raw) || !nzchar(trimws(q_raw))) {
    return(NA_character_)
  }

  trimmed <- trimws(q_raw)
  upper <- toupper(trimmed)

  # Fast path: exact ISO2 / ISO3
  if (grepl("^[A-Za-z]{2}$", trimmed)) {
    iso3 <- suppressWarnings(countrycode::countrycode(upper, "iso2c", "iso3c"))
    if (!is.na(iso3)) {
      return(as.character(iso3))
    }
  }
  if (grepl("^[A-Za-z]{3}$", trimmed)) {
    iso3 <- suppressWarnings(countrycode::countrycode(upper, "iso3c", "iso3c"))
    if (!is.na(iso3)) {
      return(as.character(iso3))
    }
  }

  qn <- normalize_country_query(trimmed)
  idx <- .get_country_index()
  if (nzchar(qn) && qn %in% names(idx$aliases)) {
    return(as.character(idx$aliases[[qn]]))
  }

  cc <- tryCatch(
    suppressWarnings(countrycode::countrycode(trimmed, "country.name", "iso3c")),
    error = function(e) NA_character_
  )
  if (length(cc) >= 1L && !is.na(cc[1L]) && nzchar(cc[1L])) {
    return(as.character(cc[1L]))
  }

  s <- country_search(trimmed, limit = 1L)
  if (nrow(s) >= 1L && s$score[1L] >= 60L) {
    return(as.character(s$iso3[1L]))
  }

  NA_character_
}


country_iso3_valid <- function(iso3) {
  iso3 <- toupper(trimws(as.character(iso3)))
  if (!grepl("^[A-Z]{3}$", iso3)) {
    return(FALSE)
  }
  idx <- .get_country_index()
  iso3 %in% idx$rows$iso3
}

country_choices <- country_selectize_choices()
