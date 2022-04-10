# Read in the saved data
tgm_morel_data <- read_csv("01-raw_data/tgm_data.csv")
inat_morel_data <- read_csv("01-raw_data/inat_data.csv")

# need to clean up datasets so that they share column names
# also add a 'source' key
# get rid of extra columns and save a singel combined dataset

