# Toronto Crime Explorer

### New city. New routines. A little more local context.

You have unpacked the suitcase. Your PRESTO card is ready. Somewhere between finding a favourite coffee shop and figuring out which subway exit to take, a different set of questions starts to surface.

*What is the area around my library like? What has been reported near the station I might use every day? Does the picture change during the summer, on weekends, or after the afternoon rush?*

Toronto Crime Explorer grew out of those questions. Built for **new students, newcomers, tourists, and curious Torontonians**, it turns historical crime records into an interactive introduction to the city—one destination, station, and time period at a time.

The motivation is simple: arriving somewhere new is easier when you have a little context to go with the map.

## Your first look around Toronto

Imagine three different first weeks in the city.

**The student** is finding a study spot and getting familiar with the streets around campus. Start with a library, choose a radius, and explore the reported activity nearby.

**The visitor** has a list of places to see: the CN Tower, the Distillery District, a day on the islands. Use the destinations view to put those places on the map and explore the surrounding records.

**The new Torontonian** is turning unfamiliar station names into a daily routine. Open the transit view to explore records around a destination's nearest station in the app's station list, then compare weekdays, weekends, and different hours.

These are starting points for exploration. The app helps you ask better questions about a place; choosing where to live, study, or visit still calls for more than a crime count.

## Follow a place. Follow a pattern.

| If you are wondering… | Try this |
| --- | --- |
| “What has been reported around this place?” | Choose a destination and turn on the local radius filter. The map, totals, and charts follow the same selection. |
| “What about the nearby subway station?” | Switch to Transit to explore the nearest **listed** station and its surroundings. |
| “Does the picture change over time?” | Start with weekly trends, zoom into daily detail, or step back to monthly totals. |
| “Are the patterns different on weekends or at certain hours?” | Adjust the weekday and hour filters, or try a peak/off-peak preset. |
| “Am I looking at bicycle theft, robbery, or something else?” | Select any combination of the three record categories. |
| “Can I take a closer look myself?” | Download daily counts with the filter settings included. |

Both maps load their street basemaps automatically. Hover over the charts for details, zoom into a period that catches your attention, and double-click the trend chart to zoom back out.

## A window into the city

![Toronto Crime Explorer: interactive transit map and weekly crime trends](preview.jpg)

The supplied data covers **January 2020–December 2023**, with **25,242 analysis records**, **15 destinations**, and **11 listed subway stations**.

Three categories form the starting point: **bicycle theft, robbery, and theft over**. This is a focused view of historical reported activity, rather than a complete picture of every type of crime in Toronto.

## Read the map with a little context

A busy patch of dots can catch your eye. What it means takes more care.

Places with more people, more visitors, or more activity can also have more reports. These counts are not adjusted for foot traffic, population, or ridership, and reported records cannot capture everything that happens in a city. The data is historical, so it cannot tell you whether a particular street is safe today.

**Use the explorer to understand patterns—not to label a neighbourhood “safe” or “dangerous,” or to choose a supposedly safe route.**

A few details help keep comparisons fair:

- **Records and incidents are different measures.** Multiple analysis records can share an event ID; the app shows both record totals and distinct IDs.
- **Bicycle theft includes all recorded statuses**, including recovered and unknown. It is not a count of bicycles still missing.
- **“Nearest station” means nearest within the 11-station list.** Distances are approximate straight-line distances, not walking routes or a search of the entire TTC network.
- **Time filters work together.** Weekly and monthly totals include only the dates and hours you selected, so the first or last period may be partial. Exam presets are illustrative, not official university calendars.

## Behind the explorer

This project was developed by a **team of six students** as a group course project for **STA 313 Data Visualization**.

Built with **R and Shiny**, it combines Leaflet maps, Plotly charts, and a reproducible data-preparation workflow. Shared filtering functions keep the maps and charts in agreement. Analytical and Shiny-module tests check the behaviour behind the interface.

Further contribution and data-lineage details are recorded in [PROVENANCE.md](PROVENANCE.md), with test results in [VALIDATION.md](VALIDATION.md).

## Sources & acknowledgements

The crime datasets used in this project come from **Toronto Police Service Open Data**:

- [Toronto Police Service — Open Data](https://www.tps.ca/data-maps/open-data/)
- [Toronto Police Service — Public Safety Data Portal](https://data.tps.ca/)
- [Toronto Police Service — Data Analytics and dashboards](https://www.tps.ca/data-maps/data-analytics/)

The project uses historical snapshots of the **Bicycle Thefts**, **Robbery**, and **Theft Over** datasets. Current downloads may cover different dates or use updated schemas, so they may not reproduce the numbers shown here exactly. Dataset documentation and applicable terms should be consulted alongside the data.

Street basemaps are provided by [OpenStreetMap contributors](https://www.openstreetmap.org/copyright). This is a student project, not an official Toronto Police Service application.

## Run locally

### 1. Get the project and install the packages

Use R 4.1 or newer. From a terminal:

```sh
git clone https://github.com/KaiwenYangUT/toronto-crime-explorer.git
cd toronto-crime-explorer
```

Install the required packages from R:

```r
install.packages(c("shiny", "bslib", "leaflet", "plotly", "ggplot2", "data.table"))
```

### 2. Prepare the data

Generated datasets are not included in Git. Place the three source CSVs in a local directory:

```text
Bicycle_Thefts_Open_Data.csv
Robbery_Open_Data.csv
Theft_Over_Open_Data.csv
```

Then build the app's data bundle from the project root:

```sh
Rscript scripts/build_data.R /absolute/path/to/source/data
```

If you already have a prepared `data/processed/crime.rds` from this project, you can skip this step. The build expects the supplied snapshot schemas; newer portal exports may need field-name adjustments.

### 3. Explore

```sh
Rscript scripts/run_app.R
```

Open the local URL printed in the terminal. An internet connection is needed for street-map tiles; the crime data is processed locally. No map API key is configured.

To check the analytical logic and application modules:

```sh
Rscript tests/test_analysis.R
Rscript tests/test_shiny.R
```

For a custom setup, `TORONTO_R_LIBRARY` selects an R package library and `TORONTO_CRIME_DATA` selects a prepared data bundle. Run all commands from the project root.
