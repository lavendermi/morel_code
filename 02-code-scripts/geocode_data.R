# reverse geolocate
# this code it modified from: https://rpubs.com/FelipeMonroy/619723

options("rgdal_show_exportToProj4_warnings"="none")
library(sp)
library(rgdal)
library(lubridate)
library(tidyverse)

merged_morel_data <- sample_n(read_csv("01-raw_data/merged_morel_data.csv"), 100)
# merged_morel_data <- read_csv("01-raw_data/merged_morel_data.csv")

startg <- Sys.time()

# Reading each of the maps. dsn is the folder of the map and layer is the name of the .shp file inside.
countries_map <- readOGR(dsn = "00-spatial_data/ne_10m_admin_0_countries", layer = "ne_10m_admin_0_countries")

ca_subdivisions <- readOGR(dsn = "00-spatial_data/canadian_census_subdivisions", layer = "lcsd000a20a_e")
us_subdivisions <- readOGR(dsn = "00-spatial_data/usa_boundaries/cb_2020_us_county_5m/", layer = "cb_2020_us_county_5m")

ecoregions_map <- readOGR(dsn = "00-spatial_data/Level_III_Ecoregions_of_North_America", layer = "North_American_Ecoregions___Level_III")

# This is a function to reverse geocoding based on coordinates
rev_geo <- function(i, lat, long) {
  # First the coordinates are transformed to spatialpoints
  points <- SpatialPoints(matrix(c(
    long,
    lat
  ), ncol = 2, nrow = 1))
  
  # Creating a projection of the coordinates on the map of countries
  proj4string(points) <- proj4string(countries_map)
  
  # first get the country so that we know which regional data map we need to work with
  country <- as.character(over(points, countries_map)$NAME)
  
  if (country == "Canada") {

    print("Canadian Eh!")
    slot(points, "proj4string") <- cat(wkt(ca_subdivisions))
    found <- over(points, ca_subdivisions)
    province <- as.character(found$PRNAME)
    level_01 <- as.character(found$CDNAME)
    level_02 <- as.character(found$CSDNAME)
    
  } else if (country == "United States of America") {

    print("Merican")
    slot(points, "proj4string") <- wkt(us_subdivisions)
    found <- over(points, us_subdivisions)
    province <- as.character(found$STATE_NAME)
    level_01 <- as.character(found$NAME)
    level_02 <- NA
    
  }
  
  # To see where the name of the country is stored in the map object, you need
  # to explore it in R and see the “data” element. In this case, “NAME” has the
  # information that we want. The function over returns the name of the country
  # given the coordinates projected in the ecoregions_map
  eco_region <- as.character(over(points, ecoregions_map)$NA_L3NAME)

  return(as.vector(c(i, country, province, level_01, level_02, eco_region)))

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
  .packages = c("sp", "rgdal"), .combine = rbind
) %dopar% {
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
names(map_info) <- c("id", "country", "state", "ecoregion")
map_info$id <- as.integer(map_info$id)


merged_morel_data <- left_join(merged_morel_data, as.data.frame(map_info), by = "id")
