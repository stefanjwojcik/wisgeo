# get all the parcels - scraping function 

# I ran this script in the firefox console to get all the links on this page: https://www.sco.wisc.edu/parcels/data-county/#v600
#var urls = document.getElementsByTagName('a');
#for (url in urls) {
#    console.log ( urls[url].href );
#}

using CSV, DataFrames

plinks = CSV.read("../../data/county_parcel_links.csv", header=0, DataFrame)
rename!(plinks, ["link", "debug", "eval", "code"])
plinks_geos = plinks[2:2:end, :] # every other line is the geo link

cnames = CSV.read("../../data/county_names.csv", header=0, DataFrame)
rename!(cnames, ["county", "typeshape", "typegeo"])

plinks_geos.county_name = cnames.county

for row in eachrow(plinks_geos)
    download(row.link, "$(row.county_name).zip")
end
    #download(row.link, row.cname"")