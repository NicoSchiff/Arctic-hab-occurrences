## %######################################################%##
#                                                          #
####     03 — Fetch HAB Occurrences by Arctic LME       ####
####             OBIS query, per-region loop            ####
####                  2025/02/03                        ####
#                                                          #
## %######################################################%##

# ---------------------------------------------------------------
# Purpose
# ---------------------------------------------------------------
# Retrieve Harmful Algal Bloom (HAB) species occurrences from
# OBIS for each Arctic Large Marine Ecosystem (LME), then map
# the results on a polar projection.
#
# Workflow:
#   • Load the HAB taxonomic reference list (AlgaeBaseR)
#   • Loop over each Arctic LME polygon:
#       1. Simplify geometry to a valid WKT (≤ 5000 chars)
#       2. Query OBIS in chunks of species
#       3. Tag occurrences with LME name + WKT metadata
#   • Combine all results into a single tibble `occ_by_lme`
#   • Plot occurrences on a polar basemap (ggOceanMaps)
#
# Inputs  : arctic_shp     (from 02_arctic_lme_shapefile.R)
#           arctic_shp_ll  (from 02_arctic_lme_shapefile.R)
#           helpers        (from 01_setup_and_helpers.R)
# Outputs : occ_by_lme                              (tibble)
#           outputs/tables/occ_by_lme.rds           (optional)
#           outputs/figures/map_arctic_lme.png      (polar map)
#
# Dependencies: 01_setup_and_helpers.R, 02_arctic_lme_shapefile.R
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 1. HAB taxonomic reference list
# ---------------------------------------------------------------
hab_tax <- download_habs_taxlist()
sp_vec  <- unique(hab_tax$ScientificName)

# ---------------------------------------------------------------
# 2. Loop over Arctic LMEs → OBIS occurrences
# ---------------------------------------------------------------
occ_by_lme <- purrr::map_dfr(
  seq_len(nrow(arctic_shp)),
  function(i) {
    lme_i  <- arctic_shp[i, ]
    name_i <- lme_i$lme_name
    message("→ ", name_i)
    
    wkt_i <- lme_to_wkt(lme_i, max_chars = 5000)
    out   <- fetch_occ_lme(wkt_i, sp_vec, chunk_size = 30)
    
    if (nrow(out) == 0) return(NULL)
    out |>
      dplyr::mutate(
        lme_name     = name_i,
        wkt_tol_used = attr(wkt_i, "tol"),
        wkt_nchar    = nchar(wkt_i)
      )
  }
)

# ---------------------------------------------------------------
# 3. Optional save / reload
# ---------------------------------------------------------------
# saveRDS(occ_by_lme, "outputs/tables/occ_by_lme.rds")
# occ_by_lme    <- readRDS("outputs/tables/occ_by_lme.rds")
# arctic_shp_ll <- readRDS("outputs/tables/arctic_lme.rds")

# ---------------------------------------------------------------
# 4. Polar map of occurrences
# ---------------------------------------------------------------
p_map <- ggOceanMaps::basemap(
  limits          = 45,
  land.col        = "grey90",
  land.border.col = "grey40",
  grid.col        = "grey70",
  grid.size       = 0.2
) +
  ggspatial::geom_sf(
    data = arctic_shp_ll,
    aes(fill = lme_name),
    color = "grey20", linewidth = 0.4, alpha = 0.55,
    inherit.aes = FALSE
  ) +
  ggspatial::geom_spatial_point(
    data = dplyr::distinct(occ_by_lme, decimalLongitude, decimalLatitude),
    aes(decimalLongitude, decimalLatitude),
    alpha = 0.6, size = 0.5, color = "black"
  ) +
  labs(
    title   = "HAB species occurrences in Arctic LMEs",
    caption = "Data: OBIS · Polygons: Marine Regions (LME)"
  ) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

# ---------------------------------------------------------------
# 5. Export
# ---------------------------------------------------------------
ggsave(
  filename = "outputs/figures/map_arctic_lme.png",
  plot     = p_map,
  width    = 10, height = 10, dpi = 320, bg = "white"
)

print(p_map)

message("✅ Script 03 completed — occurrences fetched and mapped.")
