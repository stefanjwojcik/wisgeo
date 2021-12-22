using ZipFile, 
## Download all real estate transfer data: for ALL available years
baselink ="https://www.revenue.wi.gov/SLFReportsHistSales/"
years = string.(collect(2016:2021))
months = [lpad(x, 2, "0") for x in 1:12]

for year in years
    for month in months 
        download(baselink*year*month*"CSV.zip", "data/transfer"*year*month*"CSV.zip")
    end
end

# Unzip all the files in a given path 
function unzip(file,exdir="")
    fileFullPath = isabspath(file) ?  file : joinpath(pwd(),file)
    basePath = dirname(fileFullPath)
    outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(),exdir)))
    isdir(outPath) ? "" : mkdir(outPath)
    zarchive = ZipFile.Reader(fileFullPath)
    for f in zarchive.files
        fullFilePath = joinpath(outPath,f.name)
        if (endswith(f.name,"/") || endswith(f.name,"\\"))
            mkdir(fullFilePath)
        else
            write(fullFilePath, read(f))
        end
    end
    close(zarchive)
end

# NOW unzip all the files - fails on the last date (12/12)
for year in years
    for month in months 
        unzip("data/transfer"*year*month*"CSV.zip")
    end
end

# Load all the data into a DataFrame 
csvfiles = readdir("data/")[contains.(readdir("data/"), r".csv")]
fulldf = DataFrame.(CSV.File.("data/".*csvfiles)) #makes a list
# Does final concatenation of all files
dfout = reduce(vcat, dfs, cols=:intersect)
CSV.write("data/alltransfers_2016to_2021.csv", dfout)

