## %######################################################%##
#                                                          #
####     04 — Top HAB Genera: Pacific vs Atlantic       ####
####          Arctic LMEs — Sector Comparison           ####
####                  2025/02/03                        ####
#                                                          #
## %######################################################%##

# ---------------------------------------------------------------
# Purpose
# ---------------------------------------------------------------
# Compare the most frequent Harmful Algal Bloom (HAB) genera
# between Pacific- and Atlantic-influenced Arctic Large Marine
# Ecosystems (LMEs), using occurrences retrieved from OBIS/GBIF
# (see scripts 01–03) and taxonomy harmonized with AlgaeBase.
#
# Inputs  : occ_by_lme  (from 03_fetch_occurrences_by_lme.R)
# Outputs : Arctic_hab  (cleaned + sector-tagged occurrences)
#           top_genera  (Top 15 genera per sector)
#           Figure      : outputs/figures/04_top_genera_pac_vs_atl.png
# ---------------------------------------------------------------

# Clean environment (uncomment if running standalone)
# rm(list = ls())

# ---------------------------------------------------------------
# 1. Packages
# ---------------------------------------------------------------
library(tidyverse)
library(readxl)
library(rgbif)
library(worrms)
library(tidytext)   # reorder_within(), scale_y_reordered()
library(here)       # portable paths

# ---------------------------------------------------------------
# 2. External scripts (AlgaeBase helpers)
# ---------------------------------------------------------------
# Adjust paths via `here::i_am()` in your project root, or keep
# these absolute paths for now.
source(here("R", "AlgaeBaseR.R"))
source(here("R", "compare_species.R"))
source(here("R", "AlgaeBaseapi_key.R"))

# ---------------------------------------------------------------
# 3. Taxonomy harmonization with AlgaeBase
# ---------------------------------------------------------------
# Retrieve AlgaeBase IDs for all unique scientific names
name2id <- AlgaeBase_name2id(unique(occ_by_lme$scientificName), api_key)

# Keep records resolved at species level (binomial name)
name2id_species <- name2id %>%
  filter(str_detect(scientificName, "\\s"))

# Fetch full taxonomic records from AlgaeBase IDs
id2name_species <- AlgaeBase_records_IDs_species(
  unique(na.exclude(name2id_species$acceptedNameUsageID)),
  api_key
)

# Tidy up: rename columns and drop redundant IDs
id2name_proceed <- id2name_species %>%
  select(-acceptedNameUsageID, -scientificNameID) %>%
  rename(
    acceptedNameUsage               = scientificName,
    acceptedNameUsageAuthorship     = scientificNameAuthorship,
    acceptedNameUsagewithAuthorship = scientificNamewithAuthorship
  ) %>%
  distinct()

# Detect & resolve duplicated IDs (Scrippsiella ambiguity)
id_duplicated <- id2name_proceed %>%
  filter(duplicated(raw_ID)) %>%
  distinct(raw_ID) %>%
  arrange(raw_ID) %>%
  pull(raw_ID)

id2name_proceed_corrected <- id2name_proceed %>%
  filter(!(raw_ID %in% id_duplicated & acceptedNameUsage == "Scrippsiella"))

# Merge: raw names ↔ AlgaeBase accepted taxonomy
raw_AlgaeBase <- left_join(
  name2id, id2name_proceed_corrected,
  by = c("acceptedNameUsageID" = "raw_ID")
) %>%
  distinct()

# Final AlgaeBase table
AlgaeBase <- raw_AlgaeBase %>%
  rename(parseName = parse.name) %>%
  filter(!is.na(scientificNameID)) %>%
  mutate(
    across(everything(), as.character),
    database                 = "AlgaeBase",
    scientificNameAuthorship = name_parse(scientificNamewithAuthorship)$authorship
  )

# ---------------------------------------------------------------
# 4. Build Arctic HAB occurrence table
# ---------------------------------------------------------------
Arctic_hab <- occ_by_lme %>%
  select(
    scientificName, basisOfRecord, datasetID, datasetName,
    decimalLatitude, decimalLongitude, depth, individualCount,
    institutionCode, day, month, year, eventDate,
    organismQuantity, organismQuantityType, lme_name
  ) %>%
  rename(parseName = scientificName) %>%
  left_join(AlgaeBase, by = "parseName")

# ---------------------------------------------------------------
# 5. Assign each LME to a biogeographic sector
# ---------------------------------------------------------------
# Pacific  : Bering–Chukchi gateway, North Pacific inflow
# Atlantic : North Atlantic / Nordic Seas / Baffin–Labrador
# Siberian : Russian shelf seas (sparse data, excluded)
# Central  : High Arctic (excluded, transitional)

lme_sector <- tribble(
  ~lme_name,                                  ~sector,
  # --- Pacific influence ---
  "Aleutian Islands",                         "Pacific",
  "East Bering Sea",                          "Pacific",
  "West Bering Sea",                          "Pacific",
  "Northern Bering - Chukchi Seas",           "Pacific",
  "Beaufort Sea",                             "Pacific",   # transitional via Bering Strait
  
  # --- Atlantic influence ---
  "Barents Sea",                              "Atlantic",
  "Norwegian Sea",                            "Atlantic",
  "Greenland Sea",                            "Atlantic",
  "Iceland Shelf and Sea",                    "Atlantic",
  "Faroe Plateau",                            "Atlantic",
  "Labrador - Newfoundland",                  "Atlantic",
  "Canadian Eastern Arctic - West Greenland", "Atlantic",
  "Hudson Bay Complex",                       "Atlantic",
  
  # --- Siberian / Central (excluded from comparison) ---
  "Kara Sea",                                 "Siberian",
  "Laptev Sea",                               "Siberian",
  "East Siberian Sea",                        "Siberian",
  "Central Arctic",                           "Central",
  "Canadian High Arctic - North Greenland",   "Central"
)

# Join + restrict to Pacific vs Atlantic
Arctic_hab <- Arctic_hab %>%
  left_join(lme_sector, by = "lme_name") %>%
  filter(sector %in% c("Pacific", "Atlantic"),
         !is.na(genus), genus != "")

# ---------------------------------------------------------------
# 6. Top 15 most frequent genera per sector
# ---------------------------------------------------------------
top_genera <- Arctic_hab %>%
  count(sector, genus, sort = TRUE) %>%
  group_by(sector) %>%
  slice_max(n, n = 15) %>%
  ungroup()

print(top_genera)

# ---------------------------------------------------------------
# 7. Visualization
# ---------------------------------------------------------------
p_top_genera <- ggplot(
  top_genera,
  aes(x = n,
      y = reorder_within(genus, n, sector),
      fill = sector)
) +
  geom_col(show.legend = FALSE) +
  scale_y_reordered() +
  facet_wrap(~ sector, scales = "free") +
  scale_fill_manual(values = c(Pacific = "#1f77b4", Atlantic = "#d62728")) +
  labs(
    title    = "Top 15 most frequent HAB genera in the Arctic",
    subtitle = "Pacific- vs Atlantic-influenced Large Marine Ecosystems",
    x        = "Number of occurrences",
    y        = NULL,
    caption  = "Data: OBIS / GBIF · Taxonomy: AlgaeBase"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    strip.text         = element_text(face = "bold", size = 13),
    plot.title         = element_text(face = "bold"),
    plot.subtitle      = element_text(color = "grey30"),
    axis.text.y        = element_text(face = "italic"),
    panel.grid.major.y = element_blank()
  )

print(p_top_genera)

# ---------------------------------------------------------------
# 8. Export
# ---------------------------------------------------------------
dir.create(here("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("outputs", "tables"),  recursive = TRUE, showWarnings = FALSE)

ggsave(
  filename = here("outputs", "figures", "04_top_genera_pac_vs_atl.png"),
  plot     = p_top_genera,
  width    = 10, height = 6, dpi = 300, bg = "white"
)

write_csv(top_genera,  here("outputs", "tables", "04_top_genera_by_sector.csv"))
write_csv(Arctic_hab,  here("outputs", "tables", "04_arctic_hab_occurrences.csv"))

message("✅ Script 04 completed — figure & tables saved in outputs/")
