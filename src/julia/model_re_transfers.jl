using CSV, DataFrames, Dates, Pipe

# Function to process prices 
mfn1(x) = parse(Float64, replace(x, r"\$|,|\s" => ""))

# Loading in the transfers data - ParcelIdentification
dfout = CSV.read("data/alltransfers_2016to_2021.csv", DataFrame);
# Modify price column 
dfout = @pipe dfout |> 
    combine(_, :, :TotalRealEstateValue => ByRow(mfn1) => :TotalRealEstateValue) |> 
    combine(_, :, :TotalRealEstateValue => ByRow(log) => :LogReValue)

# Get the date of the sale close 
    # Where length of date is 7 digits then the first digit is a single digit month 
function process_dates(weird_dates)
    out = Date.(repeat(["01011984"], length(weird_dates)), dateformat"mmddyyyy") # dummy object
    eight_digit_dates = findall(x -> length(string(x)) == 8, weird_dates);
    eight_dig_closedate = Date.(string.(weird_dates[eight_digit_dates]), dateformat"mmddyyyy")
    seven_digit_dates = findall(x -> length(string(x)) == 7, weird_dates);
    seven_dig_closedate = Date.(string.(weird_dates[seven_digit_dates]), dateformat"mddyyyy")
    out[eight_digit_dates] .= eight_dig_closedate
    out[seven_digit_dates] .= seven_dig_closedate
    return out
end

dfout.closedate = process_dates(dfout.DateConveyed)

# Filter down to properties that were bought and sold within the five year span 
same_id = DataFrame(ParcelIdentification = unique(dfout.ParcelIdentification[findall(nonunique(dfout[!, [:ParcelIdentification]]))]) )
same_id_df = @pipe same_id |>
    leftjoin(_, dfout, on=:ParcelIdentification) |> 
    groupby(_, :ParcelIdentification) |> 
    combine(_, :closedate => minimum => :buydate, :closedate => maximum => :selldate)
#### Filter to properties held more than six months 
same_id_df.days_held = Dates.value.(same_id_df.selldate .- same_id_df.buydate)
same_id_df = @pipe same_id_df |> 
    filter(:days_held => x -> x > 60, _) 

# Create mini df for buying selling merge 
mindf = dfout[!, [:closedate, :TotalRealEstateValue,:ParcelIdentification]]

# Merge back with the original data (on buy and sell date) to get purchase prices and selling prices 
buy_data = @pipe same_id_df[!, [:ParcelIdentification, :buydate, :days_held]] |> 
    leftjoin(_, mindf, on = [:ParcelIdentification => :ParcelIdentification, :buydate => :closedate]) |> 
    rename(_, Dict("TotalRealEstateValue" => "BuyPrice")) |> 
    groupby(_, [:ParcelIdentification,:buydate, :days_held]) |>
    combine(_, :BuyPrice => sum => :BuyPrice)

sell_data = @pipe same_id_df[!, [:ParcelIdentification, :selldate]] |> 
    leftjoin(_, mindf, on = [:ParcelIdentification => :ParcelIdentification, :selldate => :closedate]) |> 
    rename(_, Dict("TotalRealEstateValue" => "SellPrice")) |> 
    groupby(_, [:ParcelIdentification,:selldate]) |>
    combine(_, :SellPrice => sum => :SellPrice)

# Join buy and sell data together, then finall join back with features from the larger dataset 
redf = @pipe innerjoin(sell_data, buy_data, on=:ParcelIdentification) |> 
            combine(_, :, [:SellPrice, :BuyPrice] => ((x,y) -> x - y ) => :PriceDelta ) |> 
            filter(:BuyPrice => x -> x > 0, _)

# Calculate YoY ROI for the property based on the buy price and the days held 
redf.YoYROI = (redf.PriceDelta ./ redf.BuyPrice) ./ (redf.days_held ./ 365)
#Gadfly.plot(redf, x=:YoYROI, y=:days_held, Geom.point)

# Join the ROI data back to the original dataset 
cols_to_grab = [:GrantorType, :GrantorGranteeRelationship, :Township, :PropertyType, :PredominateUse, 
                :MultiFamilyUnits, :AgrOwnerLessThan5years, :TotalAcres, :WaterFrontIndicator, 
                :TransferType, :OwnerInterestTransferred, :GrantorRightsRetained, :ParcelIdentification, 
                :PropertyAddress, :ManagedForestLandAcres, :SplitParcel, :WaterFrontFeet, :LogReValue, :closedate]

ucols = [:GrantorType, :GrantorGranteeRelationship, :Township, :PropertyType, :PredominateUse, 
                :MultiFamilyUnits, :AgrOwnerLessThan5years, :TotalAcres, :WaterFrontIndicator, 
                :TransferType, :OwnerInterestTransferred, :GrantorRightsRetained, 
                :PropertyAddress, :ManagedForestLandAcres, :SplitParcel, :WaterFrontFeet, :LogReValue, :closedate]                
df_features = select(dfout, cols_to_grab) |> 
    groupby(_, [:ParcelIdentification, :closedate]) |>
    combine(_, )


duplicated_rows = nonunique(df_features, [:ParcelIdentification, :closedate])

redf_out = @pipe redf |> 
    leftjoin(dfout[!, [:]])

# load in the tax data to join with the transfers 
#taxdata = CSV.read()

# Plot histogram of prices by Home USE type 

#Gadfly.plot(dfout, x=:LogReValue, color=:PredominateUse, Geom.histogram)
#Gadfly.plot(filter(:TotalRealEstateValue => x -> x < 900000, dfout), x=:TotalRealEstateValue, color=:PredominateUse, Geom.histogram)