# build a script to use this service intelligently
# https://daymet.ornl.gov/web_services

# round all lat long to 1 decimal places http://wiki.gis.com/wiki/index.php/Decimal_degrees
round_to <- 1

  merged_morel_data %>% 
  mutate(short_lat = round(latitude, round_to), short_long = round(longitude, round_to)) %>% 
  group_by(short_lat, short_long) %>% 
  summarise(n = n()) %>% 
    arrange(-n)
