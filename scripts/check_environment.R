local_library <- Sys.getenv("TORONTO_R_LIBRARY", "../../work/r-library")
if (dir.exists(local_library)) .libPaths(c(normalizePath(local_library), .libPaths()))
packages <- c("shiny", "bslib", "leaflet", "plotly", "ggplot2", "data.table")
for (p in packages) {
  available <- requireNamespace(p, quietly = TRUE)
  cat(p, if (available) as.character(utils::packageVersion(p)) else "MISSING", "\n")
}
cat(R.version.string, "\n")
