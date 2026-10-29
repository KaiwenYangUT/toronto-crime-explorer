#!/usr/bin/env Rscript
# Usage from repository root: Rscript scripts/build_data.R /path/to/original/data
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: Rscript scripts/build_data.R /path/to/source/data")
if (!requireNamespace("data.table", quietly = TRUE)) stop("Install data.table before building data.")
source("R/analysis.R")
source_dir <- normalizePath(args[1], mustWork = TRUE)
spec <- c("Bicycle_Thefts_Open_Data.csv" = "Bicycle theft",
          "Robbery_Open_Data.csv" = "Robbery", "Theft_Over_Open_Data.csv" = "Theft over")
manifest <- list()
tables <- lapply(names(spec), function(filename) {
  path <- file.path(source_dir, filename)
  if (!file.exists(path)) stop("Missing input: ", filename)
  raw <- data.table::fread(path, data.table = FALSE)
  required <- c("EVENT_UNIQUE_ID", "OCC_YEAR", "OCC_MONTH", "OCC_DAY", "OCC_HOUR", "LONG_WGS84", "LAT_WGS84", "LOCATION_TYPE", "PREMISES_TYPE")
  if (!all(required %in% names(raw))) stop("Missing columns in ", filename)
  if (spec[[filename]] == "Bicycle theft" && !"STATUS" %in% names(raw)) stop("Missing bicycle status.")
  month <- match(substr(raw$OCC_MONTH, 1, 3), month.abb)
  date_text <- sprintf("%04d-%02d-%02d", as.integer(raw$OCC_YEAR), month, as.integer(raw$OCC_DAY))
  dates <- suppressWarnings(as.Date(date_text, format = "%Y-%m-%d"))
  # Round-trip check rejects normalized invalid calendar dates as well as missing dates.
  valid_date <- !is.na(dates) & format(dates, "%Y-%m-%d") == date_text
  x <- data.frame(event_id = as.character(raw$EVENT_UNIQUE_ID), date = dates,
    hour = as.integer(raw$OCC_HOUR), weekday = as.integer(format(dates, "%u")),
    category = unname(spec[[filename]]), longitude = as.numeric(raw$LONG_WGS84),
    latitude = as.numeric(raw$LAT_WGS84),
    status = if ("STATUS" %in% names(raw)) as.character(raw$STATUS) else "Not applicable",
    location_type = as.character(raw$LOCATION_TYPE), premises_type = as.character(raw$PREMISES_TYPE),
    stringsAsFactors = FALSE)
  # Broad plausibility box, not a municipal boundary containment test.
  valid <- valid_date & !is.na(x$event_id) & nzchar(x$event_id) & x$hour %in% 0:23 &
    is.finite(x$longitude) & x$longitude > -80 & x$longitude < -78 &
    is.finite(x$latitude) & x$latitude > 43 & x$latitude < 45
  valid[is.na(valid)] <- FALSE
  in_period <- valid & !is.na(x$date) & x$date >= as.Date("2020-01-01")
  x <- x[which(in_period), , drop = FALSE]
  x[is.na(x)] <- "Unknown"
  before <- nrow(x)
  x <- unique(x)
  manifest[[filename]] <<- list(file = filename, md5 = unname(tools::md5sum(path)),
    source_rows = nrow(raw), invalid_rows = sum(!valid),
    valid_rows_before_2020 = sum(valid & !is.na(dates) & dates < as.Date("2020-01-01")),
    exact_duplicate_rows_removed = before - nrow(x), retained_rows = nrow(x),
    first_date = as.character(min(x$date)), last_date = as.character(max(x$date)))
  x
})
events <- do.call(rbind, tables)
events <- events[order(events$date, events$category, events$event_id), ]
rownames(events) <- NULL
bundle <- list(events = events,
  places = read.csv("config/places.csv", stringsAsFactors = FALSE),
  stations = read.csv("config/stations.csv", stringsAsFactors = FALSE),
  manifest = manifest, schema_version = 1L)
validate_bundle(bundle)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(bundle, "data/processed/crime.rds", version = 3, compress = "xz")
cat(sprintf("Built %s analysis records (%s distinct event IDs), %s through %s.\n",
  nrow(events), length(unique(events$event_id)), min(events$date), max(events$date)))
print(manifest)
