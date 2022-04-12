# Read in the saved data
source("02-code-scripts/01_init.R")
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
      mutate(source_db = "tgm", datetime = ymd_hms(datetime), scientific_name = NA),
    inat_morel_data %>%
      select(scientific_name, latitude, longitude, datetime) %>%
      mutate(source_db = "inat", datetime = ymd_hms(datetime))
  )

write_csv(merged_morel_data, "01-raw_data/merged_morel_data.csv")
# https://stackoverflow.com/questions/8751497/latitude-longitude-coordinates-to-state-code-in-r
# https://rpubs.com/FelipeMonroy/619723
# https://www.naturalearthdata.com


#### This is play / test code to see what plotting would look like. This will be
#### moved to a better place at some point

plot_region <- map_data(map = "world", region = c("canada"))


morel_ggplot <-
  ggplot(data = plot_region) +
  geom_polygon(aes(
    x = long, # base map
    y = lat,
    group = group
  ),
  fill = "white", # background color
  color = "darkgray"
  ) + # border color
  coord_quickmap() +
  geom_point(
    data = merged_morel_data %>%
      filter(source_db == "inat"), # these are the research grade observation points
    mapping = aes(
      x = longitude,
      y = latitude,
      fill = scientific_name
    ), # changes color of point based on scientific name
    color = "black", # outline of point
    shape = 21, # this is a circle that can be filled
    alpha = 0.7
  ) + # alpha sets transparency (0-1)
  theme_bw() + # just a baseline theme
  theme(
    plot.background = element_blank(), # removes plot background
    panel.background = element_rect(fill = "white"), # sets panel background to white
    panel.grid.major = element_blank(), # removes x/y major gridlines
    panel.grid.minor = element_blank()
  ) # removes x/y minor gridlines

morel_ggplot
