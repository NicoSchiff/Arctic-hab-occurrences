# Arctic HAB Occurrences by Large Marine Ecosystem (LME)

Exploratory workflow to retrieve **Harmful Algal Bloom (HAB) species occurrences** 
from [OBIS](https://obis.org/) across **Arctic Large Marine Ecosystems (LMEs)**, 
using polar-aware spatial queries.

---

## Objectives

1. Retrieve the global LME polygons from [Marine Regions](https://marineregions.org/) 
   via `mregions2`.
2. Subset Arctic LMEs.
3. Query [OBIS](https://obis.org/) for HAB taxa occurrences within each LME, 
   using an **adaptive WKT simplification** to respect API URL limits.
4. Visualize the results on a polar projection (`ggOceanMaps`).

---

## Dependencies

```r
install.packages(c(
  "sf", "dplyr", "purrr", "stringr", "tidyr", "ggplot2",
  "rnaturalearth", "ggOceanMaps", "ggspatial",
  "mregions2", "robis", "remotes"
))
source("https://raw.githubusercontent.com/NicoSchiff/AlgaeBaseR/main/R/download_habs_taxlist.R")
```
---

## Usage

Open the RStudio project and run the steps individually:

```r
source("R/00_setup.R")
source("R/01_get_lme_arctic.R")     # → arctic_shp
source("R/02_fetch_occurrences.R")  # → occ_by_lme
source("R/03_map_arctic_lme.R")     # → outputs/figures/map_arctic.png
```

## Key functions
| Function          | Purpose                                                                 |
|-------------------|-------------------------------------------------------------------------|
| `lme_to_wkt()`    | Adaptive WKT simplification (tolerance ↑ until `nchar ≤ max_chars`).   |
| `fetch_occ_lme()` | Chunked OBIS query by species vector for a given WKT polygon.          |



## Outputs

outputs/tables/occ_by_lme — occurrences joined with LME name  

outputs/figures/map_arctic_lme.png — polar map of LMEs + occurrences

<img width="3200" height="3200" alt="map_arctic_lme" src="https://github.com/user-attachments/assets/084e660e-5621-4ef5-82ea-6493bab5cd05" />



## Data sources

LMEs — Marine Regions (mregions2::mrp_get("lme"))

Occurrences — OBIS (robis::occurrence)

HAB taxa list — AlgaeBaseR



