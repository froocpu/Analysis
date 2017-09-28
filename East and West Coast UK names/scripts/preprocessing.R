#### Author: Ollie Frost
#### Created: 01 July 2017
#### Description: Analysis piece for the Direct Line Group technical challenge.

source("inputs.R")
source("functions.R")

## Get the packages you need.
ufnLibrary(c("data.table","sqldf"))

## 0. Scrape/download external data sources. ---------------------------------------
source("metadata.R")

## 1. Profile and load the data. ---------------------------------------------------
## Inspect the first 10 lines.
cat(
    paste0(
        readLines(con = file(input_cities), n = 100), collapse = "\r\n"
    )
)

## Since the data looks reasonably clean, use a fast read function from data.table to import the data.
## Returns 3173958 rows (excluding the header and empty line in the EOF) so it reconciles nicely. 
citiesData <- fread(input_cities)

  ## Count the duplicate values:
  ufn_CountDuplicates(citiesData) # returns 311 rows initially.

## 2. Perform some filtering and transformations. --------------------------
## Begin filtering out non-US and non-UK cities.
## Also check for duplicates.
citiesData <- citiesData[Country %in% c("us","gb","au","in"),]
  
  ufn_CountDuplicates(citiesData) # returns 7 dupes.

## Probe the dupes on a reduced number of columns.
sqldf("SELECT Country, City, AccentCity, Region, count(1) as Freq
      FROM citiesData
      GROUP BY Country, City, AccentCity, Region
      HAVING count(1) > 1") 

## Neither of these regions are in my stateLookup table.
## This should mean that the next join won't produce any unexpected results.

## Join on your states lookup table.
citiesData <- merge(
  x = unique(citiesData), y = stateLookup, # returns 5 states, which matches the length of westCoastStates
  by = c("Country","Region"), all.x = TRUE
)

  ufn_CountDuplicates(citiesData); # returns 0.

## Perform join on data enrichment table.
citiesDataFull = sqldf("
      SELECT
          c.Country as Country,
          c.City, c.AccentCity, c.Longitude, c.Latitude,
          COALESCE(c.State, c.Country || c.Region) as Region,
          COALESCE(ewl.EastWest, 'Other') as EastWestFlag
      FROM
          citiesData c
      LEFT OUTER JOIN
          input_EastWestLookup ewl
      ON
          c.State = ewl.State
      AND
          c.[Country] = 'us'
      ")


  

