local_library <- Sys.getenv("TORONTO_R_LIBRARY", "../../work/r-library")
if (dir.exists(local_library)) .libPaths(c(normalizePath(local_library), .libPaths()))
# Run after installing runtime dependencies and building data.
source("R/analysis.R")
source("R/explorer.R")
bundle <- readRDS("data/processed/crime.rds")
for (mode in c("destination", "station")) {
 shiny::testServer(explorer_server, args = list(bundle = bundle, mode = mode), {
  session$setInputs(dates = range(bundle$events$date), categories = crime_categories,
    weekdays = as.character(1:7), hours = c(0,23), period = "all", local = FALSE,
    place = bundle$places$id[1], radius = 300, trend_interval = "week")
  stopifnot(nrow(selected()) == nrow(bundle$events), sum(daily()$count) == nrow(selected()))
  stopifnot(grepl('"maxZoom":19', output$map, fixed = TRUE))
  stopifnot(nzchar(output$summary$html), nzchar(output$daily), nzchar(output$category),
    nzchar(output$weekday), nzchar(output$hour))
  for (category in crime_categories) {
    session$setInputs(categories = category)
    stopifnot(nrow(selected()) > 0, all(selected()$category == category))
    map <- jsonlite::fromJSON(output$map, simplifyVector = FALSE)
    methods <- vapply(map$x$calls, function(call) call$method, character(1))
    stopifnot("addTiles" %in% methods, "addMarkers" %in% methods)
    marker_call <- map$x$calls[[which(methods == "addMarkers")]]
    stopifnot(length(marker_call$args[[1]]) == nrow(selected()))
  }
  session$setInputs(categories = crime_categories)
  for (interval in c("day", "week", "month")) {
    session$setInputs(trend_interval = interval)
    chart <- jsonlite::fromJSON(output$daily, simplifyVector = FALSE)
    expected_points <- length(unique(trend_counts(daily(), interval)$date))
    stopifnot(length(chart$x$data[[1]]$x) == expected_points)
  }
  session$setInputs(trend_interval = "week")
  session$setInputs(local = TRUE)
  expected_center <- if (mode == "station") nearest_station(bundle$places[1,,drop=FALSE],bundle$stations) else bundle$places[1,,drop=FALSE]
  expected <- filter_events(bundle$events, range(bundle$events$date), center = expected_center)
  stopifnot(identical(selected()$event_id, expected$event_id), nrow(selected()) < nrow(bundle$events))
  session$setInputs(period = "final")
  stopifnot(all(as.integer(format(selected()$date,"%m")) %in% c(4,12)))
  session$setInputs(categories = character())
  stopifnot(nrow(selected()) == 0, nrow(daily()) == 0, grepl("Select one or more",output$summary$html))
  export <- output$download
  stopifnot(file.exists(export), nrow(read.csv(export)) == 0)
  session$setInputs(categories = crime_categories, local = FALSE, period = "peak")
  peak <- nrow(selected())
  session$setInputs(period = "off_peak")
  stopifnot(peak + nrow(selected()) == nrow(bundle$events))
 })
 cat("PASS:", mode, "module rendering, filters, empty export, and peak partition\n")
}
