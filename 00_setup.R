# ---- Packages ----
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

sf::sf_use_s2(FALSE)  # safer for polar geometries

# ---- Paths ----
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables",  recursive = TRUE, showWarnings = FALSE)

# ---- Custom helpers ----
source("R/utils_wkt.R")

# ---- AlgaeBaseR functions (sourced from GitHub) ----
source("https://raw.githubusercontent.com/NicoSchiff/AlgaeBaseR/main/R/download_habs_taxlist.R")
