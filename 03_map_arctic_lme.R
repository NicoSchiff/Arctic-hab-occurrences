# occ_by_lme    <- readRDS("outputs/tables/occ_by_lme.rds")
# arctic_shp_ll <- readRDS("outputs/tables/arctic_lme.rds")

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
  theme(plot.title = element_text(face = "bold", hjust = 0.5))

ggsave("outputs/figures/map_arctic_lme.png",
       p_map, width = 10, height = 10, dpi = 320, bg = "white")

p_map
