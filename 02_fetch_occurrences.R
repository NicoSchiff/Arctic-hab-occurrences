# HAB taxa reference list
hab_tax <- download_habs_taxlist()
sp_vec  <- unique(hab_tax$scientificName)

# Loop over each Arctic LME
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

# saveRDS(occ_by_lme, "outputs/tables/occ_by_lme.rds")
