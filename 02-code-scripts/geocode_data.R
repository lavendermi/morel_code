# reverse geolocate
# this code it modified from: https://rpubs.com/FelipeMonroy/619723
# https://www.infoworld.com/article/3505897/how-to-do-spatial-analysis-in-r-with-sf.html

library(sf)
library(maps)
library(lubridate)
library(tidyverse)

merged_morel_data <- sample_n(read_csv("01-raw_data/merged_morel_data.csv"), 10)
# merged_morel_data <- read_csv("01-raw_data/merged_morel_data.csv")

point_geo <- st_as_sf(merged_morel_data,
  coords = c(x = "longitude", y = "latitude"),
  crs = 4326
)

startg <- Sys.time()

# Reading each of the maps. dsn is the folder of the map and layer is the name of the .shp file inside.
countries_map <- st_read(dsn = "00-spatial_data/ne_10m_admin_0_countries", layer = "ne_10m_admin_0_countries")
# countries_map <- countries_map %>% filter(POSTAL %in% c("CA", "US"))

ca_subdivisions <- st_read(dsn = "00-spatial_data/canadian_census_subdivisions", layer = "lcsd000a20a_e")
us_subdivisions <- st_read(dsn = "00-spatial_data/usa_boundaries/cb_2020_us_county_5m/", layer = "cb_2020_us_county_5m")
ecoregions_map <- st_read(dsn = "00-spatial_data/Level_III_Ecoregions_of_North_America", layer = "North_American_Ecoregions___Level_III")

us_subdivisions <- st_transform(us_subdivisions, st_crs(ca_subdivisions))
ecoregions_map <- st_transform(ecoregions_map, st_crs(ca_subdivisions))

ca_subdivisions <- ca_subdivisions %>%
  select(PRNAME, CDNAME, CSDNAME, geometry) %>%
  rename(prov_state = PRNAME, level_01 = CDNAME, level_02 = CSDNAME)

us_subdivisions <- us_subdivisions %>%
  select(STATE_NAME, NAME, geometry) %>%
  rename(prov_state = STATE_NAME, level_01 = NAME) %>%
  mutate(level_02 = NA)

# us_subdivisions <- st_transform(us_subdivisions, st_crs(ca_subdivisions))

na_subdivisions <- rbind(ca_subdivisions, us_subdivisions)


my_results <- st_join(point_geo, countries_map,
  join = st_within
) %>%
  select(c(datetime, source_db, scientific_name, geometry, ADM0_A3)) %>%
  rename(country = ADM0_A3)

my_results <- st_transform(my_results, st_crs(ca_subdivisions))

sf::sf_use_s2(FALSE)
my_results <- st_join(my_results, na_subdivisions,
  join = st_within
)

my_results <- st_join(my_results, ecoregions_map,
  join = st_within
) %>%
  rename(eco_region = NA_L3NAME) %>%
  select(datetime, source_db, scientific_name, geometry, country, prov_state, level_01, level_02, eco_region)

