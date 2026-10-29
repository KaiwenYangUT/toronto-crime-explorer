#!/usr/bin/env Rscript
# Run from the project root. Uses the isolated task library when available;
# elsewhere, use your normal R library or set TORONTO_R_LIBRARY explicitly.
local_library <- Sys.getenv("TORONTO_R_LIBRARY", "../../work/r-library")
if (dir.exists(local_library)) .libPaths(c(normalizePath(local_library), .libPaths()))
shiny::runApp(".", host = "127.0.0.1", launch.browser = interactive())
