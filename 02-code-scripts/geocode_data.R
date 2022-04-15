# reverse geolocate
# this code it modified from: https://rpubs.com/FelipeMonroy/619723


library(sf)
library(maps)
library(lubridate)
library(tidyverse)

sf::sf_use_s2(FALSE)

merged_morel_data <- sample_n(read_csv("01-raw_data/merged_morel_data.csv"), 10)
# merged_morel_data <- read_csv("01-raw_data/merged_morel_data.csv")

startg <- Sys.time()

# Reading each of the maps. dsn is the folder of the map and layer is the name of the .shp file inside.
countries_map <- st_read(dsn = "00-spatial_data/ne_10m_admin_0_countries", layer = "ne_10m_admin_0_countries")
countries_map$geometry <- countries_map$geometry %>% 
  s2::s2_rebuild() %>%
  sf::st_as_sfc()

ca_subdivisions <- st_read(dsn = "00-spatial_data/canadian_census_subdivisions", layer = "lcsd000a20a_e")
us_subdivisions <- st_read(dsn = "00-spatial_data/usa_boundaries/cb_2020_us_county_5m/", layer = "cb_2020_us_county_5m")

ecoregions_map <- st_read(dsn = "00-spatial_data/Level_III_Ecoregions_of_North_America", layer = "North_American_Ecoregions___Level_III")

# This is a function to reverse geocoding based on coordinates
rev_geo <- function(i, lat, long) {
  i = 1
  lat = as.numeric(40.84935)
  long = as.numeric(-73.87119)
  # First the coordinates are transformed to spatiallong_lat
  print("made it here 01")
  long_lat <- sf::st_as_sf(data.frame(long, lat), coords = c("long", "lat"))
  
  # Creating a projection of the coordinates on the map of countries
  # latitude <- c(40.84935,40.76306,40.81423,40.63464,40.71054)
  # longitude <- c(-73.87119,-73.90235,-73.93443,-73.88090,-73.83765)
  # x = data.frame(longitude, latitude)
  # sf_x <- sf::st_as_sf(x, coords = c("longitude", "latitude"))
  # print("made it here 02")
  # sf::st_crs(long_lat) <- sf::st_crs(countries_map)
  
  # first get the country so that we know which regional data map we need to work with
  # country <- as.character(sf::st_within(long_lat, countries_map)$NAME)
  print("made it here 03")
  country <- map.where(database="world", st_coordinates(long_lat))
  
  print("made it here 04")
  if(country == "Canada") {
    print("made it here 04A")
    print("Canadian Eh!")
    sf::st_crs(long_lat) <- sf::st_crs(ca_subdivisions)
    found <- sf::st_within(long_lat, ca_subdivisions)
    province <- as.character(found$PRNAME)
    level_01 <- as.character(found$CDNAME)
    level_02 <- as.character(found$CSDNAME)
    
  } else if(country == "USA") {
    print("made it here 04B")
    print("Merican")
    sf::st_crs(long_lat) <- sf::st_crs(us_subdivisions)
    found <- sf::st_within(long_lat, us_subdivisions)
    province <- as.character(found$STATE_NAME)
    level_01 <- as.character(found$NAME)
    level_02 <- NA
    
  } else {
    print("made it here xxx")
    print("nowhere")
    province <- NA
    level_01 <- NA
    level_02 <- NA
  }
  
  # To see where the name of the country is stored in the map object, you need
  # to explore it in R and see the “data” element. In this case, “NAME” has the
  # information that we want. The function over returns the name of the country
  # given the coordinates projected in the ecoregions_map
  # eco_region <- as.character(over(long_lat, ecoregions_map)$NA_L3NAME)

  return(as.vector(c(i, country, province, level_01, level_02)))

}

library(snow)
library(foreach)
library(doParallel)

cl <- makeCluster(detectCores() - 1)
registerDoParallel(cl)

# Now for each row in the dataset I am going to return the reverse geocoding
# I am using parallel processing here to make the process faster
map_info <- foreach(
  i = 1:nrow(merged_morel_data),
  .packages = c("sf", "maps", "tidyverse"), .combine = rbind
) %dopar% {
  print("made it here 05")
  rev_geo(
    i,
    as.numeric(merged_morel_data[i, "latitude"]),
    as.numeric(merged_morel_data[i, "longitude"])
  )
}

stopCluster(cl)

endg <- Sys.time()
(endg - startg)

merged_morel_data$id <- (1:nrow(merged_morel_data))
map_info <- as.data.frame(map_info)
# names(map_info) <- c("id", "country", "state")
map_info$id <- as.integer(map_info$id)


merged_morel_data <- left_join(merged_morel_data, as.data.frame(map_info), by = "id")


rev_geo(
  1,
  as.numeric(40.84935),
  as.numeric(-73.87119)
)
