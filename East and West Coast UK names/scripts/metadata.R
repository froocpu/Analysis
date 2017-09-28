## Get the relevant metadata for the region codes.
## fread() will try and get the data directly from the URL.
## We will join these back to the main data later.
codes <- "http://www.maxmind.com/download/geoip/misc/region_codes.csv"
regions <- fread(codes, col.names = c("Country","Region","State"))

## Create final data table.
stateLookup <- data.table(
  Country =  tolower(regions$Country),
  Region = regions$Region,
  State = regions$State
)

## Clean up.
rm(codes, regions)