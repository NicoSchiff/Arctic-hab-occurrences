## %######################################################%##
#                                                          #
####     01 — Setup, Helpers & Reference Taxonomy       ####
####          Arctic HAB Bibliometric Pipeline          ####
####                  2025/02/03                        ####
#                                                          #
## %######################################################%##

# ---------------------------------------------------------------
# Purpose
# ---------------------------------------------------------------
# Initialize the working environment for the Arctic HAB pipeline:
#   • Load required R packages (spatial, OBIS, plotting, taxonomy)
#   • Create output directories
#   • Define reusable helper functions:
#       - lme_to_wkt()    : adaptive WKT simplification for OBIS
#       - fetch_occ_lme() : chunked OBIS occurrence query
#   • Source the AlgaeBaseR helper (HAB taxonomic reference list)
#
# Inputs  : none
# Outputs : helpers loaded in the global environment
#           outputs/figures/  and  outputs/tables/  directories
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 1. Packages
# ---------------------------------------------------------------
suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tidyr)
  library(ggplot2)
  library(rnaturalearth)
  library(ggOceanMaps)
  library(ggspatial)
  library(mregions2)
  library(robis)
})

sf::sf_use_s2(FALSE)   # safer for polar geometries

# ---------------------------------------------------------------
# 2. Output directories
# ---------------------------------------------------------------
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables",  recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------
# 3. External helper — AlgaeBaseR (sourced from GitHub)
# ---------------------------------------------------------------
source("https://raw.githubusercontent.com/NicoSchiff/AlgaeBaseR/main/R/download_habs_taxlist.R")

# ---------------------------------------------------------------
# 4. Helper — Adaptive WKT simplification
# ---------------------------------------------------------------
#' Iteratively increases `dTolerance` until the WKT string fits
#' within `max_chars`. Falls back to convex hull if needed.
#'
#' @param geom      sf/sfc geometry
#' @param tol_start starting tolerance (degrees)
#' @param tol_max   maximum tolerance allowed
#' @param max_chars WKT length threshold
#' @param verbose   print progress messages
#' @return Character WKT, with attribute `tol` (final tolerance used)
lme_to_wkt <- function(geom,
                       tol_start = 0.05,
                       tol_max   = 5,
                       max_chars = 5000,
                       verbose   = TRUE) {
  
  tol <- tol_start
  g   <- sf::st_make_valid(geom)
  
  wkt <- g |>
    sf::st_simplify(dTolerance = tol, preserveTopology = TRUE) |>
    sf::st_geometry() |>
    sf::st_as_text()
  
  while (nchar(wkt) > max_chars && tol < tol_max) {
    tol <- tol * 1.15
    wkt <- g |>
      sf::st_simplify(dTolerance = tol, preserveTopology = TRUE) |>
      sf::st_geometry() |>
      sf::st_as_text()
    if (verbose) message("   ↻ tol=", round(tol, 3), " → ", nchar(wkt), " chars")
  }
  
  if (nchar(wkt) > max_chars) {
    wkt <- g |> sf::st_union() |> sf::st_convex_hull() |> sf::st_as_text()
    if (verbose) message("   ⚠ fallback convex_hull → ", nchar(wkt), " chars")
  }
  
  if (verbose) message("   ✓ final: tol=", round(tol, 3), ", ", nchar(wkt), " chars")
  attr(wkt, "tol") <- tol
  wkt
}

# ---------------------------------------------------------------
# 5. Helper — Chunked OBIS occurrence query
# ---------------------------------------------------------------
#' @param wkt        WKT polygon (character)
#' @param sp_vec     character vector of scientific names
#' @param chunk_size species per request
#' @return tibble of OBIS occurrences (empty if all chunks fail)
fetch_occ_lme <- function(wkt, sp_vec, chunk_size = 30) {
  chunks <- split(sp_vec, ceiling(seq_along(sp_vec) / chunk_size))
  purrr::map_dfr(chunks, function(sp_chunk) {
    tryCatch(
      robis::occurrence(scientificname = sp_chunk, geometry = wkt),
      error = function(e) {
        message("   ✗ chunk failed: ", e$message)
        tibble::tibble()
      }
    )
  })
}

message("✅ Script 01 completed — helpers and packages loaded.")
