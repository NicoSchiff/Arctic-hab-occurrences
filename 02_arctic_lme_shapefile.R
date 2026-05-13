## %######################################################%##
#                                                          #
####     02 — Arctic LME Shapefile Preparation          ####
####     Download, filter & reproject for polar use     ####
####                  2025/02/03                        ####
#                                                          #
## %######################################################%##

# ---------------------------------------------------------------
# Purpose
# ---------------------------------------------------------------
# Build the spatial backbone of the Arctic HAB pipeline:
#   • Download the global Large Marine Ecosystems (LME) layer
#     from Marine Regions via `mregions2`
#   • Filter LMEs flagged as Arctic
#   • Reproject to WGS84 and clip to latitudes > 50°N for
#     clean polar mapping
#
# Inputs  : Marine Regions API (LME layer)
# Outputs : arctic_shp     — Arctic LMEs in native CRS
#           arctic_shp_ll  — Arctic LMEs in WGS84, clipped > 50°N
#           outputs/tables/arctic_lme.rds  (optional save)
#
# Dependencies: 01_setup_and_helpers.R
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 1. Download global LME polygons
# ---------------------------------------------------------------
lme_shp <- mregions2::mrp_get("lme") |>
  sf::st_as_sf() |>
  sf::st_make_valid()

# ---------------------------------------------------------------
# 2. Subset Arctic LMEs
# ---------------------------------------------------------------
arctic_shp <- lme_shp |>
  dplyr::filter(!is.na(arctic)) |>
  sf::st_make_valid()

# ---------------------------------------------------------------
# 3. Reproject to WGS84 & clip > 50°N (polar display)
# ---------------------------------------------------------------
arctic_shp_ll <- arctic_shp |>
  sf::st_transform(4326) |>
  sf::st_make_valid() |>
  sf::st_crop(xmin = -180, xmax = 180, ymin = 50, ymax = 90) |>
  sf::st_make_valid()

# ---------------------------------------------------------------
# 4. Optional export
# ---------------------------------------------------------------
# saveRDS(arctic_shp_ll, "outputs/tables/arctic_lme.rds")

message("✅ Script 02 completed — Arctic LME shapefile ready.")
