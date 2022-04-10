# this script fetchs and saves the morel occurrence data from iNaturalist
# We only want to run this occasionally to refresh the data.

require(rinat)

# this queries the iNaturalist server for the data
inat_morel_data <-
  get_inat_obs(
    quality = "research", # set this if we only want research grade
    maxresults = 10000,
    geo = TRUE,
    place_id = 97394,
    taxon_id = 56830
  )

write_csv(inat_morel_data, "01-raw_data/inat_data.csv")
