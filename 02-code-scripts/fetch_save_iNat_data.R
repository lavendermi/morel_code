# this script fetchs and saves the morel occurrence data from iNaturalist

require(rinat)

# this queries the iNaturalist server for the data
inat_morel_data <-
  get_inat_obs(
    # quality = "research", # set this if we only want research grade
    geo = TRUE,
    place_id = 97394,
    taxon_id = 56830,
    maxresults = 100
  )

# for testing and gratification only
inat_morel_data %>% 
  inat_map(map = "usa", plot = TRUE)
