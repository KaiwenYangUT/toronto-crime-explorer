# Shared analytical functions. Distances are approximate great-circle metres.
crime_categories <- c("Bicycle theft", "Robbery", "Theft over")
crime_colors <- c("Bicycle theft" = "#0072B2", "Robbery" = "#D55E00", "Theft over" = "#009E73")

haversine_m <- function(lon, lat, target_lon, target_lat) {
  rad <- pi / 180
  a <- sin((lat - target_lat) * rad / 2)^2 +
    cos(lat * rad) * cos(target_lat * rad) * sin((lon - target_lon) * rad / 2)^2
  6371008.8 * 2 * asin(sqrt(pmin(1, pmax(0, a))))
}

nearest_station <- function(site, stations) {
  if (nrow(site) != 1L || !nrow(stations)) stop("Choose one destination and supply stations.")
  distances <- haversine_m(stations$longitude, stations$latitude, site$longitude, site$latitude)
  stations[which.min(distances), , drop = FALSE]
}

period_mask <- function(dates, hours, period) {
  dates <- as.Date(dates)
  month <- as.integer(format(dates, "%m"))
  day <- as.integer(format(dates, "%d"))
  weekday <- as.integer(format(dates, "%u"))
  peak <- weekday <= 5L & hours %in% c(6:8, 15:18)
  switch(period,
    all = rep(TRUE, length(dates)),
    midterm = month %in% c(2L, 10L),
    final = month %in% c(4L, 12L),
    break_time = month %in% 6:8 | (month == 12L & day >= 23L) | (month == 1L & day <= 3L),
    peak = peak,
    off_peak = !peak,
    stop("Unknown time preset: ", period)
  )
}

filter_events <- function(events, date_range, categories = crime_categories,
                          period = "all", weekdays = 1:7, hours = c(0, 23),
                          center = NULL, radius_m = 300) {
  if (length(date_range) != 2L || anyNA(date_range) || date_range[1] > date_range[2])
    stop("Choose a valid date range.")
  if (length(hours) != 2L || anyNA(hours) || hours[1] < 0 || hours[2] > 23 || hours[1] > hours[2])
    stop("Choose a valid hour range.")
  keep <- events$date >= as.Date(date_range[1]) & events$date <= as.Date(date_range[2]) &
    events$category %in% categories & events$weekday %in% weekdays &
    events$hour >= hours[1] & events$hour <= hours[2] &
    period_mask(events$date, events$hour, period)
  if (!is.null(center)) {
    if (nrow(center) != 1L || !is.finite(radius_m) || radius_m <= 0) stop("Invalid spatial filter.")
    keep <- keep & haversine_m(events$longitude, events$latitude, center$longitude, center$latitude) <= radius_m
  }
  events[which(keep), , drop = FALSE]
}

# Zero-fill selected dates; leave excluded dates as NA so lines do not bridge them.
daily_counts <- function(events, date_range, categories, period = "all", weekdays = 1:7,
                         hours = c(0, 23)) {
  dates <- seq(as.Date(date_range[1]), as.Date(date_range[2]), by = "day")
  grid <- expand.grid(date = dates, category = categories, stringsAsFactors = FALSE)
  if (!nrow(grid)) return(data.frame(date = as.Date(character()), category = character(), count = integer()))
  counts <- if (nrow(events)) aggregate(list(count = rep(1L, nrow(events))), events[c("date", "category")], sum)
    else data.frame(date = as.Date(character()), category = character(), count = integer())
  out <- merge(grid, counts, by = c("date", "category"), all.x = TRUE, sort = TRUE)
  out$count[is.na(out$count)] <- 0L
  eligible <- vapply(out$date, function(day) {
    day <- as.Date(day, origin = "1970-01-01")
    as.integer(format(day, "%u")) %in% weekdays &&
      any(period_mask(rep(day, length(seq.int(hours[1], hours[2]))), seq.int(hours[1], hours[2]), period))
  }, logical(1))
  out$count[!eligible] <- NA_integer_
  out
}

validate_bundle <- function(bundle) {
  required <- c("event_id", "date", "hour", "weekday", "category", "longitude", "latitude", "status")
  if (!is.list(bundle) || !all(c("events", "places", "stations", "manifest") %in% names(bundle)))
    stop("The data bundle is incomplete. Rebuild it with scripts/build_data.R.")
  e <- bundle$events
  if (!all(required %in% names(e)) || !nrow(e) || anyNA(e[required])) stop("Invalid or empty event data.")
  if (!inherits(e$date, "Date") || any(!e$category %in% crime_categories) ||
      any(!e$hour %in% 0:23) || any(!e$weekday %in% 1:7) ||
      any(!is.finite(e$longitude)) || any(!is.finite(e$latitude))) stop("Invalid event values.")
  for (name in c("places", "stations")) {
    x <- bundle[[name]]
    if (!all(c("id", "name", "longitude", "latitude") %in% names(x)) || !nrow(x) ||
        anyDuplicated(x$id) || anyNA(x) || any(!is.finite(x$longitude)) || any(!is.finite(x$latitude)))
      stop("Invalid ", name, " configuration.")
  }
  invisible(TRUE)
}

# Aggregate the zero-filled eligible-day grid; never treat excluded days as zero.
trend_counts <- function(daily, interval = "week") {
  if (!interval %in% c("day", "week", "month")) stop("Unknown trend interval.")
  if (!nrow(daily)) return(daily)
  bucket <- switch(interval, day = daily$date,
    week = daily$date - (as.integer(format(daily$date, "%u")) - 1L),
    month = as.Date(format(daily$date, "%Y-%m-01")))
  x <- data.frame(date = bucket, category = daily$category, count = daily$count)
  groups <- split(seq_len(nrow(x)), interaction(x$date, x$category, drop = TRUE))
  result <- do.call(rbind, lapply(groups, function(i) {
    data.frame(date = x$date[i[1]], category = x$category[i[1]],
      count = if (all(is.na(x$count[i]))) NA_real_ else sum(x$count[i], na.rm = TRUE),
      eligible_days = sum(!is.na(x$count[i])))
  }))
  rownames(result) <- NULL
  result[order(result$date, result$category), ]
}
