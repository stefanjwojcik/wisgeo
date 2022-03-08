###
library(dplyr)
library(readr)

# data to plot 
df = read_csv("~/github/wisgeo/data/allParcelsLatLong.csv")

df$full_address = paste(df$PropertyAddress, df$TVCname)