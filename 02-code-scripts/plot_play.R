# play with animating the data a bit
source("02-code-scripts/01_init.R")
require(mapdata)
require(maptools)
library(gganimate)

merged_morel_data <- read_csv("01-raw_data/merged_morel_data.csv")

usa <- map_data("usa")
canada <- map_data("worldHires", "Canada")
mexico <- map_data("worldHires", "Mexico")

base_map <- ggplot() +
  geom_polygon(
    data = usa,
    aes(x = long, y = lat, group = group),
    fill = "white",
    color = "black"
  ) +
  geom_polygon(
    data = canada, aes(x = long, y = lat, group = group),
    fill = "white", color = "black"
  ) +
  coord_quickmap() +
  theme_void()


subset_d <- sample_n(merged_morel_data, 100)
map_with_data <- ggplot() +
  geom_point(data =subset_d, aes( x = longitude, y = latitude), colour = "orange")

map_with_data

map_with_animation <- map_with_data +
  transition_time(datetime) +
  ggtitle('date: {frame_time}',
          subtitle = 'Frame {frame} of {nframes}')
num_years <- as.integer(max(subset_d$datetime) - min(subset_d$datetime) + 1)
animate(map_with_animation, nframes = nrow(subset_d))



p <- ggplot(merged_morel_data, aes(x = longitude, y = latitude)) +
  geom_point(aes(frame = datetime)) +
  ggplotly(p)
