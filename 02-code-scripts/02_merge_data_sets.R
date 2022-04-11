# Read in the saved data
source("02-code-scripts/00_init.R")
tgm_morel_data <- read_csv("01-raw_data/tgm_data.csv")
inat_morel_data <- read_csv("01-raw_data/inat_data.csv")

# need to clean up data sets so that they share column names
# also add a 'source' key
# get rid of extra columns and save a single combined data set

merged_morel_data <-
  bind_rows(
    tgm_morel_data %>%
      select(properties.lat, properties.lon, `properties.marker-createdon`) %>%
      rename(
        latitude = properties.lat,
        longitude = properties.lon,
        datetime = `properties.marker-createdon`
      ) %>%
      mutate(source_db = "tgm", datetime = ymd_hms(datetime)),
    inat_morel_data %>%
      select(latitude, longitude, datetime) %>%
      mutate(source_db = "inat", datetime = ymd_hms(datetime))
  )

write_csv(merged_morel_data, "01-raw_data/morel_data.csv")
# https://stackoverflow.com/questions/8751497/latitude-longitude-coordinates-to-state-code-in-r
# https://rpubs.com/FelipeMonroy/619723
# https://www.naturalearthdata.com