# pull in the parcel data
require(sf)
require(rgdal)
fc <- sf::st_read("~/Desktop/V7.0.0_Wisconsin_Parcels_2021_10.3_Uncompressed/V7.0.0_WISCONSIN_PARCELS_2021_10.3_Uncompressed.gdb", layer = "V700_WisconsinParcels_2021")
file_out = fc %>% st_drop_geometry() # drops the polygons from the data 