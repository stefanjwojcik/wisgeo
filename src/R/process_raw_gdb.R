# pull in the parcel data

# 1. Merge transfer data with parcels data to get the lat-long of the sale


#require(sf)
#require(rgdal)
library(dplyr)
library(stringr)
library(fuzzyjoin)
library(readr)

# NOTE: V7 parcels data lacks TAX PARCEL ID numbers, and so cannot be merged with the transfers data
# So V7 should not be used. V6 has the correct tax numbers for merging 
#fc <- sf::st_read("~/Desktop/V7.0.0_Wisconsin_Parcels_2021_10.3_Uncompressed/V7.0.0_WISCONSIN_PARCELS_2021_10.3_Uncompressed.gdb", layer = "V700_WisconsinParcels_2021")
#file_out = fc %>% st_drop_geometry() # drops the polygons from the data 

# INITIAL OPENING AND PREPROCESSING OF MEGA DATA SET - THIS FILE IS WRONG!! 
fc <- as.data.frame(sf::st_read("~/Downloads/V6.0.0_Wisconsin_Parcels_2020_10.3_Uncompressed/V6.0.0_WisconsinParcels_2020_10.3_Uncompressed.gdb"))

fc_tax = fc %>% select(-Shape) %>% drop_na(TAXPARCELID)
write_csv(as_tibble(fc_tax), "../../data/allparcels_tax_2020.csv")

fc_notax = fc %>% select(-Shape) %>% filter(is.na(TAXPARCELID))
write_csv(as_tibble(fc_notax), "../../data/allparcels_notax_2020.csv")

fc = read_csv("../../data/allparcels_tax_2020.csv")
fc_tax = fc %>% drop_na(TAXPARCELID)

### YOU CAN MERGE W/ TAXPARCELID only 

# EAU CLAIRE PARCELS DATA:
#fc <- as.data.frame(sf::st_read("~/Downloads/V600_Wisconsin_Parcels_EAU_CLAIRE.gdb"))

#trans = read_csv("~/github/wisgeo/data/alltransfers_2016to_2021.csv") 0
trans = read_csv("~/github/wisgeo/data/alltransfers_2016to_2021.csv") %>%
  select(TaxBillName, TaxBillZip, PropertyAddress, PredominateUse, PropertyType, OwnerInterestTransferred, TransferType, ParcelIdentification, CountyName, TVCname) %>%
  filter(PredominateUse == 1 & PropertyType == 2 & OwnerInterestTransferred == 1 & TransferType == 1) %>%
  mutate(PARCELID = str_replace_all(ParcelIdentification, "-", "")) %>%
  mutate(PARCELID = str_replace(PARCELID, "PRCL", "")) %>%
  filter(CountyName == "EAU CLAIRE") 

## SEE IF YOU CAN MERGE - only merges ~ 34%, for some reason 
hi = trans %>% left_join(select(fc, TAXPARCELID), by=c("PARCELID" ="TAXPARCELID"))
parcels = read_csv("~/github/wisgeo/data/Wisconsin_Parcels_2021V7.csv")


################################### ACTUAL CODE HERE 
dloaded_files = list.files("../../data/scraped_parcels")
files_to_open = dloaded_files[str_detect(dloaded_files, "V600")]
counties = read.csv("../../data/county_names.csv", header=F)
names(counties)[1] = "county_name"

for(fname in files_to_open){
  fc <- as.data.frame(sf::st_read(paste("../../data/scraped_parcels/", fname, sep="")))
  newname = str_replace(fname, ".gdb", ".csv")
  write_csv(as_tibble(fc), paste("../../data/scraped_parcels/", newname, sep=""))
}


temp = list.files("../../data/scraped_parcels", pattern="*.csv")
tempex = paste("../../data/scraped_parcels/", temp, sep="")
myfiles = lapply(tempex, read_csv)
out = do.call(rbind, myfiles)
write_csv(out, "../../data/all_scraped_counties.csv")
