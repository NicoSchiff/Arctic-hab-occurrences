# Download global LMEs and subset Arctic ones
lme_shp <- mregions2::mrp_get("lme") |>
  sf::st_as_sf() |>
  sf::st_make_valid()

arctic_shp <- lme_shp |>
  dplyr::filter(!is.na(arctic)) |>
  sf::st_make_valid()

# WGS84 + clip > 50°N for clean polar display
arctic_shp_ll <- arctic_shp |>
  sf::st_transform(4326) |>
  sf::st_make_valid() |>
  sf::st_crop(xmin = -180, xmax = 180, ymin = 50, ymax = 90) |>
  sf::st_make_valid()

# saveRDS(arctic_shp_ll, "outputs/tables/arctic_lme.rds")
