# this script fetchs and saves the morel occurrence data from The Great Morel
# We only want to run this occasionally to refresh the data.

library(httr)
library(tidyRSS)
library(tidyverse)
library(jsonlite)

url_list <- c(
  "https://www.thegreatmorel.com/maps/geojson/layer/2,3,4,5,8/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/12,13,14,15,16/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/18,19,20,21,22/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/24,25,26,27,28,29/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/31,32,33,34,35,36/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/38,39,40,41,42,43/?callback=jsonp&full=yes&full_icon_url=yes"
)

tgm_morel_data <- data.frame()

for (url in url_list) {
  req <- httr::GET(url)
  txt <- content(req, "text")
  json <- sub("jsonp(", "", txt, fixed = TRUE)
  json <- sub(");$", "", json)

  tgm_morel_data <- rbind(tgm_morel_data, jsonlite::fromJSON(json, flatten = TRUE)[["features"]])
}

write_csv(tgm_morel_data, "01-raw_data/tgm_data.csv")


