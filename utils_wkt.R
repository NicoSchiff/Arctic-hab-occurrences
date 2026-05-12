## `R/utils_wkt.R`
#' Adaptive WKT simplification
#'
#' Iteratively increases `dTolerance` until the WKT string fits within
#' `max_chars`. Falls back to convex hull if the threshold is not reached.
#'
#' @param geom        sf/sfc geometry
#' @param tol_start   starting tolerance (degrees)
#' @param tol_max     maximum tolerance allowed
#' @param max_chars   WKT length threshold
#' @param verbose     print progress messages
#'
#' @return Character WKT, with attribute `tol` (final tolerance used).
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


#' Chunked OBIS occurrence query for a species vector
#'
#' @param wkt        WKT polygon (character)
#' @param sp_vec     character vector of scientific names
#' @param chunk_size species per request
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
