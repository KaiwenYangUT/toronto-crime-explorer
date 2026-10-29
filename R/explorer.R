explorer_ui <- function(id, bundle, mode) {
  ns <- shiny::NS(id)
  dates <- range(bundle$events$date)
  bslib::layout_sidebar(
    fillable = FALSE, fill = FALSE,
    sidebar = bslib::sidebar(width = 320,
      shiny::dateRangeInput(ns("dates"), "Occurrence dates", start = dates[1], end = dates[2], min = dates[1], max = dates[2]),
      shiny::checkboxGroupInput(ns("categories"), "Record category", choices = crime_categories, selected = crime_categories),
      shiny::actionButton(ns("all_categories"), "Select all categories", class = "btn-sm"),
      shiny::selectInput(ns("period"), "Time preset", choices = c("All times" = "all", "Midterm months: Feb & Oct" = "midterm", "Final months: Apr & Dec" = "final", "Break: Jun–Aug, Dec 23–Jan 3" = "break_time", "Weekday peak: 06–08 & 15–18" = "peak", "All other hours" = "off_peak")),
      shiny::checkboxGroupInput(ns("weekdays"), "Days of week", choices = setNames(1:7, c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")), selected = 1:7, inline = TRUE),
      shiny::sliderInput(ns("hours"), "Hours (inclusive)", min = 0, max = 23, value = c(0, 23)),
      shiny::checkboxInput(ns("local"), if (mode == "station") "Filter near a destination's nearest listed station" else "Filter near a destination", FALSE),
      shiny::selectInput(ns("place"), "Destination", choices = setNames(bundle$places$id, bundle$places$name)),
      shiny::sliderInput(ns("radius"), "Radius (metres)", min = 100, max = 2000, value = 300, step = 100),
      shiny::downloadButton(ns("download"), "Download daily counts")),
    bslib::card(min_height = 620, bslib::card_header("Selected records"), shiny::uiOutput(ns("summary")), leaflet::leafletOutput(ns("map"), height = 480)),
    bslib::card(min_height = 440, bslib::card_header("Records over time"),
      shiny::radioButtons(ns("trend_interval"), "Time detail", choices = c("Daily" = "day", "Weekly" = "week", "Monthly" = "month"), selected = "week", inline = TRUE),
      shiny::tags$p(class = "small text-muted", "Totals include only the dates and hours selected. Weeks start Monday; boundary periods may be partial. Hover for counts and included days. Double-click to reset zoom."),
      plotly::plotlyOutput(ns("daily"), height = 300)),
    bslib::layout_columns(col_widths = c(4, 4, 4), min_height = 330,
      bslib::card(min_height = 330, bslib::card_header("Categories"), plotly::plotlyOutput(ns("category"), height = 260)),
      bslib::card(min_height = 330, bslib::card_header("Weekdays"), plotly::plotlyOutput(ns("weekday"), height = 260)),
      bslib::card(min_height = 330, bslib::card_header("Hours"), plotly::plotlyOutput(ns("hour"), height = 260))))
}

explorer_server <- function(id, bundle, mode) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observeEvent(input$all_categories, {
      shiny::updateCheckboxGroupInput(session, "categories", selected = crime_categories)
    })
    center <- shiny::reactive({
      if (!isTRUE(input$local)) return(NULL)
      shiny::req(input$place)
      site <- bundle$places[bundle$places$id == input$place, , drop = FALSE]
      shiny::validate(shiny::need(nrow(site) == 1, "Choose a destination."))
      if (mode == "station") nearest_station(site, bundle$stations) else site
    })
    selected <- shiny::reactive({
      shiny::req(length(input$dates) == 2, length(input$hours) == 2, input$period)
      shiny::validate(shiny::need(!anyNA(input$dates) && input$dates[1] <= input$dates[2], "Choose a valid date range."))
      filter_events(bundle$events, input$dates, input$categories,
        input$period, as.integer(input$weekdays), input$hours, center(), input$radius)
    })
    daily <- shiny::reactive({
      daily_counts(selected(), input$dates, input$categories, input$period,
        as.integer(input$weekdays), input$hours)
    })
    output$summary <- shiny::renderUI({
      x <- selected(); location <- center()
      shiny::tagList(
        shiny::tags$p(shiny::tags$strong(format(nrow(x), big.mark = ",")), " analysis records · ",
          format(length(unique(x$event_id)), big.mark = ","), " distinct event IDs"),
        shiny::tags$p(if (is.null(location)) "All supplied locations; no radius filter." else
          sprintf("Within %s m of %s%s.", input$radius, location$name,
            if (mode == "station") " (nearest in the supplied station list)" else "")),
        if (!nrow(x)) shiny::tags$p(role = "status", if (!length(input$categories)) "Select one or more record categories, or use Select all categories." else "No records match. Broaden the dates, categories, or radius."))
    })
    # Build a complete widget for each selection. This also initializes correctly
    # when a previously hidden tab is opened; no asynchronous proxy/cluster race.
    output$map <- leaflet::renderLeaflet({
      x <- selected(); location <- center()
      map <- leaflet::leaflet(options = leaflet::leafletOptions(minZoom = 0, maxZoom = 19))
      map <- leaflet::addTiles(map)
      if (nrow(x)) map <- leaflet::addMarkers(map, lng = x$longitude, lat = x$latitude,
        label = paste(x$category, x$date, sprintf("%02d:00", x$hour), sep = " · "),
        clusterOptions = leaflet::markerClusterOptions(), group = "records")
      places <- if (is.null(location)) bundle$places else location
      map <- leaflet::addCircleMarkers(map, lng = places$longitude, lat = places$latitude,
        label = places$name, radius = 6, color = "#6A3D9A", fillOpacity = 0.9, group = "destinations")
      if (!is.null(location)) {
        map <- leaflet::addCircles(map, lng = location$longitude, lat = location$latitude,
          radius = input$radius, color = "#6A3D9A", weight = 2, fillOpacity = 0.08)
        leaflet::setView(map, lng = location$longitude, lat = location$latitude, zoom = 14)
      } else leaflet::setView(map, lng = -79.42, lat = 43.7, zoom = 11)
    })
    output$daily <- plotly::renderPlotly({
      shiny::validate(shiny::need(nrow(selected()) > 0, "No records match the current filters."))
      interval <- if (is.null(input$trend_interval)) "week" else input$trend_interval
      d <- trend_counts(daily(), interval)
      if (interval == "day") d$eligible_days <- as.integer(!is.na(d$count))
      chart <- plotly::plot_ly()
      for (category in input$categories) {
        trace <- d[d$category == category, ]
        chart <- plotly::add_trace(chart, x = trace$date, y = trace$count,
          type = "scatter", mode = "lines",
          name = category, line = list(color = unname(crime_colors[category]), width = 2),
          connectgaps = FALSE,
          customdata = trace$eligible_days,
          hovertemplate = paste0("%{x|%b %d, %Y}<br>", category,
            ": %{y:,} records<br>%{customdata} included day(s)<extra></extra>"))
      }
      chart <- plotly::layout(chart,
        xaxis = list(title = NULL, type = "date", showgrid = FALSE),
        yaxis = list(title = "Records", rangemode = "tozero", tickformat = ",d"),
        legend = list(orientation = "h", x = 0, y = -0.25),
        margin = list(l = 60, r = 20, t = 15, b = 70),
        hovermode = "x unified", dragmode = "zoom")
      plotly::config(chart, displaylogo = FALSE, modeBarButtonsToRemove = c("select2d", "lasso2d"))
    })
    draw_bars <- function(field, levels, labels = levels) {
      x <- selected()
      shiny::validate(shiny::need(nrow(x) > 0, "No records match the current filters."))
      counts <- as.integer(table(factor(x[[field]], levels = levels)))
      d <- data.frame(label = factor(labels, levels = labels), count = counts)
      p <- ggplot2::ggplot(d, ggplot2::aes(label, count)) +
        ggplot2::geom_col(fill = "#0072B2") + ggplot2::labs(x = NULL, y = "Records") +
        ggplot2::theme_minimal() + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
      plotly::ggplotly(p)
    }
    output$category <- plotly::renderPlotly(draw_bars("category", crime_categories))
    output$weekday <- plotly::renderPlotly(draw_bars("weekday", 1:7, c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")))
    output$hour <- plotly::renderPlotly(draw_bars("hour", 0:23))
    output$download <- shiny::downloadHandler(
      filename = function() paste0("toronto-crime-daily-", Sys.Date(), ".csv"),
      content = function(file) {
        d <- daily()
        d$scope <- rep(if (is.null(center())) "All supplied locations" else center()$name, nrow(d))
        d$radius_m <- rep(if (is.null(center())) NA_real_ else input$radius, nrow(d))
        d$time_preset <- rep(input$period, nrow(d))
        d$selected_weekdays <- rep(paste(input$weekdays, collapse = ","), nrow(d))
        d$selected_hours <- rep(paste(input$hours, collapse = "-"), nrow(d))
        utils::write.csv(d, file, row.names = FALSE, na = "")
      })
  })
}
