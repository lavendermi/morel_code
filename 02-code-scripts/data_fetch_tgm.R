library(httr)
library(tidyRSS)

# iN_feed <- "https://www.inaturalist.org/observations.atom?verifiable=true&page=&spam=false&place_id=97394&user_id=&project_id=&taxon_id=56830&swlng=&swlat=&nelng=&nelat=&lat=&lng="
# df <- tidyfeed(iN_feed)

url_list <- c(
  "https://www.thegreatmorel.com/maps/geojson/layer/2,3,4,5,8/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/12,13,14,15,16/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/18,19,20,21,22/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/24,25,26,27,28,29/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/31,32,33,34,35,36/?callback=jsonp&full=yes&full_icon_url=yes",
  "https://www.thegreatmorel.com/maps/geojson/layer/38,39,40,41,42,43/?callback=jsonp&full=yes&full_icon_url=yes"
)

morel_data <- data.frame()

for (url in url_list) {
  req <- httr::GET(url)
  txt <- content(req, "text")
  json <- sub("jsonp(", "", txt, fixed = TRUE)
  json <- sub(");$", "", json)

  morel_data <- rbind(morel_data, jsonlite::fromJSON(json)[["features"]])
}

require(c(httr, tidyRSS))
