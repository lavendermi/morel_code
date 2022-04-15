# reverse geolocate
# this code it modified from: https://rpubs.com/FelipeMonroy/619723
library(sp)
library(rgdal)

merged_morel_data <- sample_n(read_csv("01-raw_data/merged_morel_data.csv"), 100)
# merged_morel_data <- read_csv("01-raw_data/merged_morel_data.csv")

startg <- Sys.time()

# Reading each of the maps. dsn is the folder of the map and layer is the name of the .shp file inside.
ecoregions_map <- readOGR(dsn = "01-raw_data/spatial_data/Level_III_Ecoregions_of_North_America", layer = "North_American_Ecoregions___Level_III")
# states_map <- readOGR(dsn = "01-raw_data/spatial_data/natural_earth_states_provinces", layer = "ne_10m_admin_1_states_provinces")
ca_subdivisions <- readOGR(dsn = "01-raw_data/spatial_data/canadian_census_subdivisions", layer = "lcsd000a20a_e")
us_subdivisions <- readOGR(dsn = "01-raw_data/spatial_data/usa_boundaries/cb_2020_us_county_5m/", layer = "cb_2020_us_county_5m")
# lgas_map <- readOGR(dsn = "lga_nsw_map", layer = "NSW_LGA_POLYGON_shp")

# This is a function to reverse geocoding based on coordinates
rev_geo <- function(i, lat, long) {
  # First the coordinates are transformed to spatialpoints
  points <- SpatialPoints(matrix(c(
    long,
    lat
  ), ncol = 2, nrow = 1))
  
  # Creating a projection of the coordinates on the map of countries
  proj4string(points) <- proj4string(ecoregions_map)
  # To see where the name of the country is stored in the map object, you need to explore it in R and see the “data” element. In this case, “NAME” has the information that we want. The function over returns the name of the country given the coordinates projected in the ecoregions_map
  eco_region <- as.character(over(points, ecoregions_map)$NA_L3NAME)

  # The same for state
  proj4string(points) <- proj4string(states_map)
  found <- over(points, states_map)
  country <- as.character(found$geonunit)
  state <- as.character(found$name)

  # # The same for LGA (I have only the map for NSW LGAs)
  # proj4string(points) <- proj4string(lgas_map)
  # LGA <- as.character(over(points, lgas_map)$NSW_LGA__3)

  # return(as.vector(c(country, state, LGA)))
  return(as.vector(c(i, country, state, eco_region)))
  # return(as.vector(c(eco_region)))
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
