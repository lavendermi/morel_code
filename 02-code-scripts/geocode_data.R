# reverse geolocate
# https://www.infoworld.com/article/3505897/how-to-do-spatial-analysis-in-r-with-sf.html


library(raster)
library(terra)
library(sf)
library(tidyverse)
library(parallel)

source("02-code-scripts/source_parallel_sf.R")

# uncomment the line below to work with a subset of the data (for testing)
# merged_morel_data <- sample_n(read_csv("01-raw_data/merged_morel_data.csv"), 100)

merged_morel_data <-
  read_csv("01-raw_data/merged_morel_data.csv")

# apply a CRS to the point data and turn it into a spatial df
point_geo <- st_as_sf(merged_morel_data,
  coords = c(x = "longitude", y = "latitude"),
  crs = 4326
)

startg <- Sys.time()

# Load all of the maps
countries_map <-
  st_read(
    dsn = "00-spatial_data/ne_10m_admin_0_countries",
    layer = "ne_10m_admin_0_countries"
  )

ca_subdivisions <-
  st_read(
    dsn = "00-spatial_data/canadian_census_subdivisions",
    layer = "lcsd000a20a_e"
  )

us_subdivisions <-
  st_read(
    dsn = "00-spatial_data/usa_boundaries/cb_2020_us_county_5m/",
    layer = "cb_2020_us_county_5m"
  )

ecoregions_map <-
  st_read(
    dsn = "00-spatial_data/Level_III_Ecoregions_of_North_America",
    layer = "North_American_Ecoregions___Level_III"
  )

lulc_map <-
  raster("00-spatial_data/north_america_2015_v2/NA_NALCMS_2015_v2_land_cover_30m/NA_NALCMS_2015_v2_land_cover_30m.tif")


# set the CRS for all of the maps (except the countries_map) to be the same CRS
point_geo <- st_transform(point_geo, st_crs(countries_map))
us_subdivisions <- st_transform(us_subdivisions, st_crs(ca_subdivisions))
ecoregions_map <- st_transform(ecoregions_map, st_crs(ca_subdivisions))

# keep only the wanted variables and rename to a common names
ca_subdivisions <- ca_subdivisions %>%
  select(PRNAME, CDNAME, CSDNAME, geometry) %>%
  rename(prov_state = PRNAME, level_01 = CDNAME, level_02 = CSDNAME)

# keep only the wanted variables and rename to a common names
us_subdivisions <- us_subdivisions %>%
  select(STATE_NAME, NAME, geometry) %>%
  rename(prov_state = STATE_NAME, level_01 = NAME) %>%
  mutate(level_02 = NA)

# now we can join the two data frames to together so that we don't need to do it
# twice, once for each country. This will cause problems later on as we have
# duplicate points on shared boundaries (US / Canada border for example)
na_subdivisions <- rbind(ca_subdivisions, us_subdivisions)

# set sf_use_s2 to false to deal with the shared boundaries mentioned above. This
# just ignores the errors.
sf::sf_use_s2(FALSE)

# First step is to figure out which country the point belongs to
my_results <- st_par(point_geo, st_join,
  n_cores = 3,
  countries_map,
  join = st_within
) %>%
  select(c(datetime, source_db, scientific_name, geometry, ADM0_A3)) %>%
  rename(country = ADM0_A3)

# give our results a CRS
my_results <- st_transform(my_results, st_crs(ca_subdivisions))

# Reverse geo-locate the census or county subdivisions for each observation
my_results <- st_par(my_results, st_join,
  n_cores = 3,
  na_subdivisions,
  join = st_within
)

# Reverse geo-locate the ecoregion for each observation
my_results <- st_par(my_results, st_join,
  n_cores = 3,
  ecoregions_map,
  join = st_within
) %>%
  rename(eco_region = NA_L3NAME) %>%
  select(datetime, source_db, scientific_name, geometry, country, prov_state, level_01, level_02, eco_region)

# Land use land cover from raster - SLOW
my_results <- add_column(lulc = terra::extract(lulc_map, point_geo), my_results)

# This is just a timer so that we can gauge how long it is going to take. Or to
# know how long it took.
endg <- Sys.time()
(endg - startg)

write_csv(my_results, "01-raw_data/merged_morel_data_plus.csv")



