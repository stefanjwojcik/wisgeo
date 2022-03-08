# Processing the Wisconsin Parcels data 
# THESE DATA HAVE SERIOUS IDENTITY RESOLUTION ISSUES 
# 1: TAXPARCELID IS SAID TO BE THE BEST COLUMN WHEN IT IS NOT NULL


# PLAN 1: APPEND ALL OF THE FOLLOWING 
# 1: Find all with one single, complete record in the parcels data - ON TAXPARCELID (AND COUNTY NAME)
# 2: Find all with one single, complete record in the parcels data - ON MYPARCELID 
# 3: 

# PLAN 2: Use fuzzy matching on all available information to 

using DataFrames, CSV, RCall

# Load and transform the data: 
out = CSV.read("data/Wisconsin_Parcels_2021V7.csv", DataFrame)

dups = out |> 
    (data -> combine(data, :, :TAXPARCELID => :MYPARCELID)) |> 
    (data -> filter(:ESTFMKVALUE => x -> x != "NA", data)) |> 
    (data -> filter(:SITEADRESS => x -> x != "NA", data))
# FILL IN MISSING IN MYPARCELID
dups.MYPARCELID[findall(x -> x == "NA", dups.MYPARCELID)] .= dups.PARCELID[findall(x -> x == "NA", dups.MYPARCELID)]    
## REPLACE NON-NUMERIC VALUES 
dups = dups |> 
    (data -> combine(data, :, :MYPARCELID => x -> replace.(x, r"-|" => ""), renamecols=false)) |> 
    (data -> groupby(data, :MYPARCELID)) |> 
    (data -> combine(data, :, :Column1 => length => :dups)) |> 
    (data -> filter(:dups => x -> x > 1, data))

    |>
    (data -> select(data, [:MYPARCELID, :CONAME, :ESTFMKVALUE])) |> 
    (data -> groupby(data, [:MYPARCELID])) |> 
    (data -> combine(data, :, dups => nrow))

