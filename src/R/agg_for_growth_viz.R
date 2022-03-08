# Make basic county-level aggregated growth data based on estimated fair market values
# Purpose is only for a slick-looking UI / MAP page 

library(dplyr)
library(stringr)
library(readr)
library(lubridate)
library(tidyr)
library(stringr)
library(fuzzyjoin)

#LOAD THE FULL PARCELS SET - ideally want one single listing per property here 
out = read_csv("../../data/Wisconsin_Parcels_2021V7.csv", col_types = paste(rep("c", 47), collapse=""))%>%
  mutate(MYPARCELID = TAXPARCELID)
# MYPARCELID created hered 
out$MYPARCELID[which(is.na(out$MYPARCELID))] <- out$PARCELID[which(is.na(out$MYPARCELID))]  
out = out %>% 
  drop_na(MYPARCELID) %>%
  mutate(MYPARCELID = str_remove_all(MYPARCELID, "[^0-9.-]|-"))

####### LOOKING AT THE DUPLICATES 
this= out[duplicated(paste(out$MYPARCELID, out$CONAME)), ]
# some missing parcel iDs
sum(duplicated(out$MYPARCELID))/nrow(out)
# lots missing site addresses
sum(duplicated(out$MYPARCELID))/nrow(out)
# 37 % are residential properties 
sum(str_detect(this$PROPCLASS, "1"), na.rm=T)/nrow(this)
# 25% are undeveloped land
sum(str_detect(this$PROPCLASS, "5"), na.rm=T)/nrow(this)

# DROPPING DUPLICATES 
out= out[!duplicated(paste(out$MYPARCELID, out$CONAME)), ]
out = out %>%
  anti_join(this, by=c("MYPARCELID", "CONAME"))

# Load transfers and limit to arms-length sales -MERGE WITH PARCELS 
trans = read_csv("../../data/alltransfers_2016to_2021.csv") %>%
  filter(PredominateUse == 1 & PropertyType == 2 & OwnerInterestTransferred == 1 & TransferType == 1) %>%
  mutate(PARCELID = str_replace_all(ParcelIdentification, "-", "")) %>%
  mutate(PARCELID = str_replace(PARCELID, "PRCL", "")) %>%
  mutate(CountyName = str_remove_all(CountyName, "\\."))

# Experimenting with unique ID's for the transfer data AND LOOKING AT DUPLICATES 
trans$myid = paste(trans$PARCELID, trans$CertificationDate)
this = trans[which(duplicated(trans$myid)), ]# 8,670 duplicates
# drop the duplicates from this stream 
trans = trans %>%
  anti_join(this, by = "myid")

## TESTING A LEFT JOIN ON THE TRANSFER DATA - based on site address and county
trans$trans_address = iconv(paste(trans$PropertyAddress, trans$CountyName), "UTF-8", "UTF-8",sub='')
out$parcel_address = iconv(paste(out$SITEADRESS, out$CONAME), "UTF-8", "UTF-8",sub='')

hi = trans %>%
  select(TotalRealEstateValue, trans_address) %>%
  stringdist_inner_join(select(out[1:10, ], parcel_address, ESTFMKVALUE), by=c(trans_address = "parcel_address"), ignore_case=T, max_dist=2)

hi = trans %>%
  select(TotalRealEstateValue, trans_address) %>%
  inner_join(select(out, parcel_address, ESTFMKVALUE, CONAME), by=c(trans_address = "parcel_address"))


hi = trans %>%
  inner_join(out, by=c("myid" = "MYPARCELID"), c("CountyName" = "CONAME", "myid" = "MYPARCELID"))

# MUTATE TRANSFER VALUES INTO NUMBERS 
trans = trans %>%
  mutate(TotalRealEstateValue = as.numeric(str_remove_all(TotalRealEstateValue, "\\$|,")))

## MODEL OF PARCEL ESTIMATE VS. ACTUAL COST 
mod = lm(TotalRealEstateValue ~ ESTFMKVALUE + log(ESTFMKVALUE+1) + ESTFMKVALUE^2, data=trans)

# all parcels 
ap = out %>%
  filter(str_detect(PROPCLASS, "1")) %>%
  drop_na(PARCELDATE)
# parse with lubridate 
ap$year = year(mdy(ap$PARCELDATE))

# Group by county, aggregate estimated fair market value, lat, long

ap_out = ap %>%
  filter(year > 2014) %>%
  group_by(CONAME, year) %>%
  summarise(LATITUDE = mean(LATITUDE, na.rm = T), LONGITUDE = mean(LONGITUDE, na.rm = T), ESTFMKVALUE = mean(ESTFMKVALUE, na.rm = T), nobs =n() ) %>%
 na.omit()
  
ap_max = ap_out %>%
  group_by(CONAME) %>%
  filter(year == max(year, na.rm=T) ) %>%
  mutate(maxfmkt = ESTFMKVALUE) %>%
  select(-ESTFMKVALUE)

ap_min = ap_out %>%
  group_by(CONAME) %>%
  filter(year == min(year, na.rm=T)) %>%
  mutate(minfmkt = ESTFMKVALUE) %>%
  select(-ESTFMKVALUE)

out = ap_min %>%
  select(CONAME, minfmkt) %>%
  inner_join(ap_max, ON = "CONAME") %>%
  mutate(ESTFMKVALUE = (maxfmkt - minfmkt) /(minfmkt) * 100) 

write_csv(out, "../../data/county_level_growth_2021.csv")
