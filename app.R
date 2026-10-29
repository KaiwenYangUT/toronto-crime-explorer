# Start from the repository root with shiny::runApp(".").
required <- c("shiny", "bslib", "leaflet", "plotly", "ggplot2")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Missing packages: ", paste(missing, collapse = ", "), ". See README.md.")
source("R/analysis.R")
source("R/explorer.R")
data_path <- Sys.getenv("TORONTO_CRIME_DATA", "data/processed/crime.rds")
if (!file.exists(data_path)) stop("Build the data first: Rscript scripts/build_data.R /path/to/source/data")
bundle <- readRDS(data_path)
validate_bundle(bundle)
coverage <- range(bundle$events$date)
ui <- bslib::page_navbar(
  title = "Toronto Crime Explorer",
  fillable = FALSE,
  id = "main_nav", selected = "Introduction",
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  header = shiny::tags$div(class = "container-fluid py-2",
    shiny::tags$p(sprintf("Historical reported records · %s to %s", coverage[1], coverage[2])),
    shiny::tags$p(class = "small text-muted", "Counts describe selected records, not personal safety or exposure-adjusted risk. Approximate locations and reporting practices limit interpretation.")),
  bslib::nav_panel("Introduction",
    bslib::layout_columns(col_widths = 12,
      bslib::card(
        bslib::card_header("Understand reported crime patterns around Toronto destinations"),
        shiny::tags$h2("Explore places. Compare times. Understand the context."),
        shiny::tags$p("Toronto Crime Explorer brings together historical bicycle-theft, robbery, and theft-over records to help students, visitors, and analysts explore patterns around university libraries, attractions, and nearby transit stations."),
        shiny::tags$p(sprintf("The supplied records cover %s through %s, with %s analysis records across three categories.", coverage[1], coverage[2], format(nrow(bundle$events), big.mark = ","))),
        shiny::tags$h3("Start exploring"),
        shiny::tags$ol(
          shiny::tags$li("Choose Destinations to explore a library or attraction, or Transit to explore its nearest station from the supplied station list."),
          shiny::tags$li("Keep all categories or select any combination. Turn on the local radius filter to focus the map and every chart on the same area."),
          shiny::tags$li("Compare weekly trends by default; switch to daily detail or monthly totals. Adjust dates and time presets to answer a specific question.")),
        shiny::actionButton("open_destinations", "Explore destinations", class = "btn-primary"),
        shiny::actionButton("open_transit", "Explore transit")),
      bslib::card(bslib::card_header("What the numbers can tell you"),
        shiny::tags$p("These are historical reported records, not predictions of personal safety. Differences in foot traffic, reporting rates, and approximate locations affect comparisons. Use the About the data page to review the definitions and limitations.")))),
  bslib::nav_panel("Destinations", explorer_ui("destinations", bundle, "destination")),
  bslib::nav_panel("Transit", explorer_ui("transit", bundle, "station")),
  bslib::nav_panel("About the data", bslib::layout_columns(col_widths = 12,
    bslib::card(bslib::card_header("How to interpret this explorer"),
      shiny::tags$p("Explore bicycle theft, robbery, and theft-over records around selected Toronto destinations and the nearest station in this app's limited station list."),
      shiny::tags$ul(
        shiny::tags$li("Every map and chart uses the same date, category, hour, weekday, and optional radius filters."),
        shiny::tags$li("Bicycle theft includes stolen, recovered, and unknown statuses. It is not a count of currently missing bicycles."),
        shiny::tags$li("Exact duplicates across the retained analysis fields are collapsed. Multiple analysis records can share an event ID; distinct event IDs are also shown."),
        shiny::tags$li("Distances use a spherical great-circle approximation. They are not walking routes. The nearest listed station may not be the nearest station in the full TTC network."),
        shiny::tags$li("Exam and break presets are illustrative month/date rules, not official university calendars."),
        shiny::tags$li("Street-map tiles are requested from OpenStreetMap automatically in your browser. No API key is configured.")),
      shiny::tags$p("Dataset source links and redistribution terms still require verification. This working copy has not been approved for public data redistribution.")))))
server <- function(input, output, session) {
  shiny::observeEvent(input$open_destinations, bslib::nav_select("main_nav", "Destinations"))
  shiny::observeEvent(input$open_transit, bslib::nav_select("main_nav", "Transit"))
  explorer_server("destinations", bundle, "destination")
  explorer_server("transit", bundle, "station")
}
shiny::shinyApp(ui, server)
