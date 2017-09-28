---
title: "Data Science Challenge - Walkthrough"
author: "Oliver Frost"
date: "July 2, 2017"
output: html_document
---



## 0. Preliminaries {.tabset .tabset-fade .tabset-pills}
### a. Hypothesis

Prove or disprove:

> ‚ÄúSince the UK was one of the main countries that colonised the USA, and the UK is on the east side of the USA there are more towns/cities with UK names on the east coast of the US rather than the west coast.‚Äù


### b. Main aims

- Given the limited time frame of the task, I wanted to focus on building a working model of the data that could be queried in more detail later, while still providing the answers to some of the more obvious questions that could be asked of the data, **while attempting to stay within the scope as much as possible.** 
- To ensure that readable documentation was produced that was easy to follow along and test.
- I wanted to ensure that the project was reproducible as much as possible.

### c. Questions

However, from my initial impressions of the data I did have a few questions I wanted to answer prior to building something more complex:

* Do countries who were a part of the British colony (US, India, Australia) indeed share place names with the UK?
* If that's true, will we see more shared place names on the east coast than the west coast?
* If a difference exists, is it significant?
* Can the matching place names be traced to specific regions of the UK?


### d. Definitions

The East Coast states with coastal access to the Atlantic Ocean include:

- Maine 
- New Hampshire 
- Massachusetts 
- Rhode Island 
- Connecticut 
- New York 
- New Jersey 
- Delaware 
- Maryland 
- Virginia 
- North Carolina 
- South Carolina 
- Georgia 
- Florida

Similarly, the West Coast states with coastal access to the Pacific Ocean include:

- California
- Oregon
- Washington
- Alaska
- Hawaii


### e. Notes

Taken from the *readme* at <https://www.maxmind.com/en/free-world-cities-database>:

> Please note: The database is no longer updated or maintained. This database contains duplicate and incorrect entries. It is provided as-is, and we are unable to provide support for it. For a cleaner database, try GeoNames, but they may lack some cities included in our data."

This was an important consideration when performing ceratin types of data manipulations and analyses.


### f. Tools

I used a combination of R for the analysis and documentation and Power BI for the bulk of the data visualisation:

* The data was too large in it's original form to be loaded directly into Power BI or Excel - **R can load the data into memory** and profile it quickly.
* R and R Studio provides functionality to write **markdown** documents, enabling me to effectively write documentation as I go.
* I can import useful open-source libraries exist for various functions like **running SQL queries** on the data, or for importing data directly into memory as a table from a URL.
* **Power BI is a free, powerful visualisation tool** which has R components for loading, transforming and plotting data (should I need them.) 



## 1. Data preparation {.tabset .tabset-fade .tabset-pills}
### a. Profiling

It is worth profiling data to forsee any potential issues that may cause time to be wasted when loading or analysing a particular data set, even if flat files appear to be regular and clean.

These are some of the technical details about the file found using **Notepad++**:

* The original data file was encoded using ANSI encoding.
* The file contained **3173960 rows** including a header and an empty line at the end.
* The header suggests that there are **7 columns** in total.
* The delimiter was a comma and there are no quoted identifiers.

A preview of the main data set:


```
## Warning in readLines(con = file(input_cities), n = 10): cannot open file
## 'data/worldcitiespop.txt': No such file or directory
```

```
## Error in readLines(con = file(input_cities), n = 10): cannot open the connection
```



### b. Loading

The data was read in from a local file using the **data.table** library, which also imports useful functionality for data manipulation as well as the fast loading of large tables into memory:

```
citiesData <- data.table::fread(input_cities)
```



The same library provides extra flexibility by allowing the user to import data straight into memory from a URL without having to download the data locally, which was done for the region code metadata:  


```r
codes <- "http://www.maxmind.com/download/geoip/misc/region_codes.csv"
regions <- data.table::fread(codes, col.names = c("Country","Region","State"))

head(regions)
```

```
##    Country Region               State
## 1:      AD     02             Canillo
## 2:      AD     03              Encamp
## 3:      AD     04          La Massana
## 4:      AD     05              Ordino
## 5:      AD     06 Sant Julia de Loria
## 6:      AD     07    Andorra la Vella
```

The *str* and *summary* base functions were used to reconcile the row count between source and target while also providing some useful insights into the dataset as a whole.


```r
str(citiesData)
```

```
## Classes 'data.table' and 'data.frame':	3173958 obs. of  7 variables:
##  $ Country   : chr  "ad" "ad" "ad" "ad" ...
##  $ City      : chr  "aixas" "aixirivali" "aixirivall" "aixirvall" ...
##  $ AccentCity: chr  "Aix‡s" "Aixirivali" "Aixirivall" "Aixirvall" ...
##  $ Region    : chr  "06" "06" "06" "06" ...
##  $ Population: int  NA NA NA NA NA NA 20430 NA NA NA ...
##  $ Latitude  : num  42.5 42.5 42.5 42.5 42.5 ...
##  $ Longitude : num  1.47 1.5 1.5 1.5 1.48 ...
##  - attr(*, ".internal.selfref")=<externalptr>
```

```r
summary(data.frame(citiesData))
```

```
##    Country              City            AccentCity       
##  Length:3173958     Length:3173958     Length:3173958    
##  Class :character   Class :character   Class :character  
##  Mode  :character   Mode  :character   Mode  :character  
##                                                          
##                                                          
##                                                          
##                                                          
##     Region            Population          Latitude        Longitude       
##  Length:3173958     Min.   :       7   Min.   :-54.93   Min.   :-179.983  
##  Class :character   1st Qu.:    3732   1st Qu.: 11.63   1st Qu.:   7.303  
##  Mode  :character   Median :   10779   Median : 32.50   Median :  35.280  
##                     Mean   :   47720   Mean   : 27.19   Mean   :  37.089  
##                     3rd Qu.:   27990   3rd Qu.: 43.72   3rd Qu.:  95.704  
##                     Max.   :31480498   Max.   : 82.48   Max.   : 180.000  
##                     NA's   :3125978
```

Some of the more notable insights include:

- **There are 234 unique country codes in the data.** We obviously do not need all of these, so we can assume that the dataset will be significantly smaller once we have filtered out the countries we need.
- **Population is sparsely populated.** With 3125978 NA values, it seems unlikely that we will be able to use this column effectively for anything interesting. This will be confirmed once the countries we're interested in are filtered.
- **The accuracy/reliability of the data is questionable.** The queries below suggest that Tokyo's population is approximately 31 million people, whereas more recent data suggests the population is closer to 37.8 million. Similarly, these data also indicate that New Delhi has a population of approximately 10.92 million, but in 2011 it was closer to 21.75 million.


```r
dplyr::filter(citiesData, Population > 10000000)
```

```
##    Country      City AccentCity Region Population  Latitude Longitude
## 1       br sao paulo  S„o Paulo     27   10021437 -23.47329 -46.66580
## 2       cn  shanghai   Shanghai     23   14608512  31.04556 121.39972
## 3       in    bombay     Bombay     16   12692717  18.97500  72.82583
## 4       in     delhi      Delhi     07   10928270  28.66667  77.21667
## 5       in new delhi  New Delhi     07   10928270  28.60000  77.20000
## 6       jp     tokyo      Tokyo     40   31480498  35.68500 139.75139
## 7       kr     seoul      Seoul     11   10323448  37.59850 126.97830
## 8       ph    manila     Manila     D9   10443877  14.60420 120.98220
## 9       pk   karachi    Karachi     05   11627378  24.90560  67.08220
## 10      ru    moscow     Moscow     48   10381288  55.75222  37.61556
```

- **Duplicates** - you can also see that some rows contain multiple entries. This could pose a problem when performing joins later on. The data also includes 311 exact duplicates.


```r
ufn_CountDuplicates(citiesData) # see scripts/functions.r to see how this works.
```

```
## [1] 311
```

The main concern is not the accuracy of the population column, but it is the not **knowing when the data was last maintained**. It is possible that some cities have changed their names, or that this data was last updated many years ago and contains errors or **missing cities**. 

This data will not be perfect, and we can assume that the majority of cities still exist now as they did when the last release was published. There will be some things we can do to clean this data up, but we should press on.

**Fun fact:** 
These are the cities with populations of 10 or less:


```r
dplyr::filter(citiesData, Population <= 10)
```

```
##   Country        City  AccentCity Region Population  Latitude  Longitude
## 1      gl    neriunaq    Neriunaq     03          7 64.466667 -50.316667
## 2      gl    tasiusaq    Tasiusaq     03          7 73.366667 -56.050000
## 3      gl   timerliit   Timerliit     03          7 65.833333 -53.250000
## 4      lu     crendal     Crendal     01         10 50.057778   5.898056
## 5      lu     schleif     Schleif     01          8 49.990556   5.857500
## 6      pa el porvenir El Porvenir     09         10  9.565278 -78.953333
## 7      ru  aliskerovo  Aliskerovo     15          7 67.766667 167.583333
```



## 2. Filtering and transformations. {.tabset .tabset-fade .tabset-pills}
### a. Filtering

Filter out the countries we're not interested in:


```r
## Specify the country codes you are interested in bringing through to analyse.
input_colonyCountries <- c("gb","us","au","in") 

## Filter the data table.
citiesData <- citiesData[Country %in% input_colonyCountries]
```

How many *exact* duplicates exist at this point?


```r
ufn_CountDuplicates(citiesData)
```

```
## [1] 7
```

Because R has a wide range of libraries available for analysis, it is entirely possible to use SQL queries inside your R scripts. The **sqldf** permits you to use a form of SQL (SQLite) to query data. This approach is useful because: 

- It can combine a number of analytical steps into one query.
- SQL is expressive, so users of SQL can follow what you are trying to do.
- The sqldf library performs well. If we were to use this code in a serious production setting we would benefit from using only R code, but for the purpose of quick ad-hoc analysis it is fine to use.

Let's investigate the dupes:


```
##   Country            City      AccentCity Region Freq
## 1      us         buffalo         Buffalo     MO    2
## 2      us       granville       Granville     MO    2
## 3      us    mount vernon    Mount Vernon     MO    2
## 4      us    prairie city    Prairie City     MO    2
## 5      us        riverton        Riverton     MO    2
## 6      us saint catharine Saint Catharine     KY    2
## 7      us      stringtown      Stringtown     MO    2
```

Neither of these regions are on the east or west coasts, so it should not affect the next stages of the analysis too drastically, if at all.

### b. Wrangling

Let's merge the results of **citiesData** with the **stateLookup** data table that was created in ```scripts/metadata.R``` : 


```r
## Create final data table.
stateLookup <- data.table(
  Country =  tolower(regions$Country),
  Region = regions$Region,
  State = regions$State
)

citiesData <- merge(
  x = unique(citiesData), y = stateLookup, # returns 5 states, which matches the length of westCoastStates
  by = c("Country","Region"), all.x = TRUE
)
```

No more duplicate rows exist at this point:

```r
ufn_CountDuplicates(citiesData)
```

```
## [1] 0
```

The data currently looks like so:


```r
head(citiesData)
```

```
##    Country Region                         City
## 1:      au     00              cascade station
## 2:      au     00                    longridge
## 3:      au     00            longridge station
## 4:      au     01 australian capital territory
## 5:      au     01                    belconnen
## 6:      au     01                     campbell
##                      AccentCity Population  Latitude Longitude
## 1:              Cascade Station         NA -29.03333  167.9667
## 2:                    Longridge         NA -29.05000  167.9333
## 3:            Longridge Station         NA -29.05000  167.9333
## 4: Australian Capital Territory         NA -35.50000  149.0000
## 5:                    Belconnen         NA -35.21667  149.0833
## 6:                     Campbell         NA -35.30000  149.1500
##                           State
## 1:                           NA
## 2:                           NA
## 3:                           NA
## 4: Australian Capital Territory
## 5: Australian Capital Territory
## 6: Australian Capital Territory
```

One final join to the **EastwestLookup** created in the ```inputs.r``` file:



The final processed file for analysis looks like so:


```r
str(citiesDataFull)
```

```
## 'data.frame':	210444 obs. of  7 variables:
##  $ Country     : chr  "au" "au" "au" "au" ...
##  $ City        : chr  "cascade station" "longridge" "longridge station" "australian capital territory" ...
##  $ AccentCity  : chr  "Cascade Station" "Longridge" "Longridge Station" "Australian Capital Territory" ...
##  $ Longitude   : num  168 168 168 149 149 ...
##  $ Latitude    : num  -29 -29.1 -29.1 -35.5 -35.2 ...
##  $ Region      : chr  "au00" "au00" "au00" "Australian Capital Territory" ...
##  $ EastWestFlag: chr  "Other" "Other" "Other" "Other" ...
```


### c. Results

This dataset powers the Shiny dashboard. The full results set is stored under the ```data``` directory as ```data/Cities_ProcessedOutput.csv``` :

    write.table(citiesDataFull, "data/Cities_ProcessedOutput.csv", row.names = FALSE, sep = ";")
    

## 3. Analysis {.tabset .tabset-fade .tabset-pills}
### a. Does the UK share place names with Australia? 

Let's begin gaining some of the basic insights. **Yes**, Australia does indeed share some place names:


```
##    AccentCity                       Region Longitude  Latitude
## 1   Longridge                         au00  167.9333 -29.05000
## 2    Kingston Australian Capital Territory  149.1333 -35.31667
## 3     Lyneham Australian Capital Territory  149.1333 -35.26667
## 4  Abbotsford              New South Wales  151.1333 -33.85000
## 5    Aberdare              New South Wales  151.3667 -32.83333
## 6    Aberdeen              New South Wales  150.8900 -32.16588
## 7   Aberfoyle              New South Wales  152.0167 -30.26667
## 8   Abernethy              New South Wales  151.4000 -32.90000
## 9    Abington              New South Wales  151.1833 -30.28333
## 10     Albury              New South Wales  146.9239 -36.07494
## 11 Alexandria              New South Wales  151.2000 -33.91667
## 12     Alston              New South Wales  148.9833 -33.98333
## 13    Appleby              New South Wales  150.8500 -30.96667
## 14      Ashby              New South Wales  153.1833 -29.43333
## 15   Ashfield              New South Wales  151.1167 -33.88333
## 16    Ashford              New South Wales  151.0931 -29.32191
## 17     Ashley              New South Wales  149.8167 -29.31667
## 18  Aylmerton              New South Wales  150.5167 -34.41667
## 19  Ballimore              New South Wales  148.9000 -32.20000
## 20   Balmoral              New South Wales  151.5833 -33.06667
```
The number of towns with UK place names:

```r
nrow(aus)
```

```
## [1] 1064
```
As a proportion of all of the distinct towns and cities in Australia:

```r
totalCities <- nrow(citiesDataFull[citiesDataFull$Country == 'au',])

nrow(aus) / totalCities * 100
```

```
## [1] 9.724888
```

I find it fairly interesting that *nearly 10% of Australian places share a name with a place in the UK*.

**Note: **I decided to match on the City column rather than the AccentCity column, as the City column has standardised the names.

However, I did notice something about the data when querying the Australia dataset. Take the query below for example, where I want to try and calculate the number of cities each Australian town shares in the UK: 


```
##          City       AusRegion CountSharedUKCities
## 1  abbotsford New South Wales                   1
## 2  abbotsford        Victoria                   1
## 3   abbotsham        Tasmania                   1
## 4    aberdare New South Wales                   1
## 5    aberdeen New South Wales                   2
## 6   aberfeldy        Victoria                   1
## 7   aberfoyle New South Wales                   1
## 8   abernethy New South Wales                   1
## 9    abington New South Wales                   1
## 10  addington        Victoria                   4
## 11     albury New South Wales                   2
## 12  aldershot      Queensland                   1
## 13 alexandria New South Wales                   1
## 14     alford South Australia                   3
## 15  allestree        Victoria                   1
## 16 alphington        Victoria                   1
## 17     alston New South Wales                   1
## 18      alton      Queensland                   2
## 19       alva      Queensland                   1
## 20      alvie        Victoria                   1
```

This highlights an interesting feature of our original data set. In the original data file, there are indeed 16 occurrences of a city/town/village called **Sutton** in the UK, however the accuracy of these entries is again questionable: 


```r
citiesData[citiesData$AccentCity == "Sutton" & citiesData$Country == "gb",]
```

```
##     Country Region   City AccentCity Population Latitude Longitude
##  1:      gb     C3 sutton     Sutton         NA 52.38333  0.100000
##  2:      gb     D3 sutton     Sutton         NA 52.88333 -1.650000
##  3:      gb     D5 sutton     Sutton         NA 53.60000 -1.166667
##  4:      gb     E1 sutton     Sutton         NA 53.91667 -0.916667
##  5:      gb     F7 sutton     Sutton         NA 52.10000 -2.683333
##  6:      gb     G6 sutton     Sutton         NA 53.78333 -0.316667
##  7:      gb     I9 sutton     Sutton         NA 52.75000  1.533333
##  8:      gb     J7 sutton     Sutton         NA 54.23333 -1.250000
##  9:      gb     J9 sutton     Sutton         NA 53.18333 -0.800000
## 10:      gb     K3 sutton     Sutton         NA 52.56667 -0.383333
## 11:      gb     M5 sutton     Sutton         NA 51.55000  0.716667
## 12:      gb     N5 sutton     Sutton         NA 52.06667  1.350000
## 13:      gb     N8 sutton     Sutton         NA 51.35000 -0.200000
## 14:      gb     P3 sutton     Sutton         NA 52.01667 -1.550000
## 15:      gb     Z6 sutton     Sutton         NA 52.10000 -0.200000
## 16:      gb     Z8 sutton     Sutton         NA 53.26667 -2.933333
##                           State
##  1:              Cambridgeshire
##  2:                  Derbyshire
##  3:                   Doncaster
##  4:    East Riding of Yorkshire
##  5:               Herefordshire
##  6: Kingston upon Hull, City of
##  7:                     Norfolk
##  8:             North Yorkshire
##  9:             Nottinghamshire
## 10:                Peterborough
## 11:             Southend-on-Sea
## 12:                     Suffolk
## 13:                      Sutton
## 14:                Warwickshire
## 15:        Central Bedfordshire
## 16:   Cheshire West and Chester
```

Some manual Google searches highlight some of the inaccuracies by showing us the full and proper names of these towns:

```
##  1:              Cambridgeshire - Sutton
##  2:                  Derbyshire - Sutton-on-the-Hill
##  3:                   Doncaster - Sutton
##  4:    East Riding of Yorkshire - Full Sutton
##  5:               Herefordshire - Sutton St Nicholas
##  6: Kingston upon Hull, City of - Sutton-on-Hull
##  7:                     Norfolk - Sutton
##  8:             North Yorkshire - Sutton-in-Craven
##  9:             Nottinghamshire - Sutton-in-Ashfield
## 10:                Peterborough - Sutton // Possible dupe of Cambridgeshire
## 11:             Southend-on-Sea - Sutton
## 12:                     Suffolk - Sutton
## 13:                      Sutton - Sutton // Possibly in London
## 14:                Warwickshire - Sutton Coldfield
## 15:        Central Bedfordshire - Sutton
## 16:   Cheshire West and Chester - Sutton Weaver
```

This is fairly common, as Sutton has origins from centuries ago. From Wikipedia:

> Sutton is an English-language surname of England and Ireland. One origin is from Anglo-Saxon where it is derived from sudh, suth, or su√∞, and tun referring to the generic placename "Southtown".

We can also see from the results that Kingston, Preston, Weston, Broughton and Middleton may also share a degree of variation according to their specific locations in the UK.

This raises the question on what we should classify as a *match* in terms of place names. Does **Sutton-in-Ashfield in Nottinghamshire** match **Sutton in New South Wales in Australia**? Ideally, we would perform further data enrichment on the data we have, or simply replace the current dataset with a more accurate and better maintained dataset (which probably would give us a more accurate answer.)

** In this instance, I continued to analyse the data as is.** The observation that Sutton in New South Wales in Australia is validated since there exists at least one town/city/village in the UK called Sutton as well, but take this into consideration when making our final conclusions.



### b. Does the UK share place names with India?

Not as many, but there are some shared names!


```
##    AccentCity                      Region Longitude Latitude
## 1    Aberdeen Andaman and Nicobar Islands  92.73333 11.66667
## 2       Boath              Andhra Pradesh  78.33333 19.33333
## 3       Dores                     Gujarat  70.96667 20.71667
## 4         Rug            Himachal Pradesh  77.02194 31.20472
## 5        Bala           Jammu and Kashmir  74.75139 32.97778
## 6      Dingle           Jammu and Kashmir  74.16667 33.76944
## 7       Isham           Jammu and Kashmir  73.95972 34.09722
## 8         Kea           Jammu and Kashmir  74.13611 33.15556
## 9      Langar           Jammu and Kashmir  74.89028 32.66806
## 10        Rug           Jammu and Kashmir  74.48472 33.10556
## 11     Timble           Jammu and Kashmir  74.20278 33.76667
## 12      Manor                 Maharashtra  72.91667 19.75000
## 13       More                 Maharashtra  72.92583 18.35389
## 14      Patna                   Karnataka  74.86667 12.76667
## 15 Whitefield                   Karnataka  77.75000 12.96667
## 16      Patna                      Orissa  85.88333 21.63333
## 17     Barmer                   Rajasthan  71.38333 25.75000
## 18       Barr                   Rajasthan  74.10000 26.08333
## 19       Boot                   Rajasthan  71.45000 25.43333
## 20       Rora                   Rajasthan  73.45000 27.55000
```
The number of places with UK place names:

```r
nrow(india)
```

```
## [1] 44
```
As a proportion of all of the towns in India:

```r
totalCities <- nrow(citiesDataFull[citiesDataFull$Country == 'in',])

nrow(india) / totalCities * 100
```

```
## [1] 0.1105167
```

### c. Does the UK share place names with the **east coast** of the US?

You betcha:


```
##      AccentCity      Region Longitude Latitude
## 1      Abington Connecticut -72.00722 41.86056
## 2       Andover Connecticut -72.37083 41.73722
## 3       Ashford Connecticut -72.12194 41.87306
## 4          Avon Connecticut -72.83111 41.80972
## 5     Berkshire Connecticut -73.26000 41.40861
## 6        Bolton Connecticut -72.43389 41.76889
## 7        Boston Connecticut -73.40778 41.27806
## 8   Bridgewater Connecticut -73.36667 41.53500
## 9       Bristol Connecticut -72.94972 41.67167
## 10   Buckingham Connecticut -72.52278 41.71222
## 11     Buckland Connecticut -72.55111 41.79611
## 12      Burnham Connecticut -72.61861 41.79917
## 13   Canterbury Connecticut -71.97139 41.69833
## 14     Cheshire Connecticut -72.90111 41.49889
## 15      Chester Connecticut -72.45139 41.40306
## 16 Chesterfield Connecticut -72.21500 41.42722
## 17   Colchester Connecticut -72.33250 41.57556
## 18     Cornwall Connecticut -73.32972 41.84361
## 19     Coventry Connecticut -72.30556 41.77000
## 20     Cromwell Connecticut -72.64583 41.59500
```
The number of towns with UK place names:

```r
nrow(muricaEast)
```

```
## [1] 2761
```

As a proportion of all of the distinct towns and cities on the east coast:

```r
totalCities <- nrow(citiesDataFull[citiesDataFull$Country == 'us' & citiesDataFull$EastWestFlag == "East",])

nrow(muricaEast) / totalCities * 100
```

```
## [1] 5.892019
```

As a proportion of all US cities:

```r
nrow(muricaEast) / nrow(citiesDataFull[citiesDataFull$Country == 'us',])
```

```
## [1] 0.01944613
```

### d. Does the UK share place names with the **west** coast of the US?

Conversely, we do not see a smaller number of matching town/city names on the west coast - in fact, we see considerably more on the west coast than we do the east coast.


```
##       AccentCity Region Longitude Latitude
## 1         Barrow Alaska -156.7886 71.29056
## 2      Broadmoor Alaska -147.8758 64.82389
## 3       Buckland Alaska -161.1231 65.97972
## 4        Chatham Alaska -134.9436 57.51528
## 5          Craig Alaska -133.1483 55.47639
## 6        Douglas Alaska -134.3925 58.27556
## 7          Eagle Alaska -141.2000 64.78806
## 8         Gordon Alaska -141.2058 69.68000
## 9         Hadley Alaska -132.2867 55.53472
## 10      Hamilton Alaska -163.8942 62.89611
## 11          Hope Alaska -149.6403 60.92028
## 12       Houston Alaska -149.8181 61.63028
## 13 Port Clarence Alaska -166.8458 65.26222
## 14  Port William Alaska -152.5828 58.49222
## 15      Ridgeway Alaska -151.0853 60.53194
## 16   Saint Marys Alaska -163.1658 62.05306
## 17    Saint Paul Alaska -170.2750 57.12222
## 18        Sutton Alaska -148.8942 61.71139
## 19         Wales Alaska -168.0875 65.60917
## 20     Waterfall Alaska -133.2406 55.29722
```

Number of distinct towns:

```r
nrow(muricaWest)
```

```
## [1] 576
```

As a proportion of all of the distinct towns and cities on the west coast:

```r
totalCities <- nrow(citiesDataFull[citiesDataFull$Country == 'us' & citiesDataFull$EastWestFlag == "West",])

nrow(muricaWest) / totalCities * 100
```

```
## [1] 5.614035
```
As a proportion of all US cities:

```r
nrow(muricaWest) / nrow(citiesDataFull[citiesDataFull$Country == 'us',])
```

```
## [1] 0.004056852
```

So while the proportion of places in the US with UK names is roughly the same between the east and west coasts (only ~0.3% difference) there is a substantial difference in the number of places with UK names between the east and west coasts (2761 on the East Coast compared to 576 on the West.)

**Note** According to the 2010 Census, the East Coast has a population of approximately 112 million compared to the 48 million inhabitants on the West Coast.

### e. Which US states contain the most places with UK names?

For the east coast:


```r
df <- data.frame(table(muricaEast$Region))
df[order(df$Freq, decreasing = TRUE),]
```

```
##              Var1 Freq
## 14       Virginia  375
## 10       New York  322
## 6        Maryland  306
## 4         Georgia  289
## 11 North Carolina  258
## 7   Massachusetts  216
## 13 South Carolina  201
## 9      New Jersey  169
## 3         Florida  150
## 5           Maine  133
## 8   New Hampshire  130
## 1     Connecticut   98
## 2        Delaware   74
## 12   Rhode Island   40
```

This finding is supported by the fact that Virginia was one of the first colonies to be founded when the British first came to America, starting at Jamestown.

The west coast:


```r
data.frame(table(muricaWest$Region))
```

```
##         Var1 Freq
## 1     Alaska   23
## 2 California  243
## 3     Oregon  110
## 4 Washington  200
```

It seems that Hawaii has no shared names with the UK!

### f. Which UK regions have the most places shared with the US, on the east coast or the west coast?


Top 10 English counties with the most shared place names from the **East Coast**:

```r
dplyr::filter(ukCounts, EastWestFlag == "East" & Freq > 10)[1:10,]
```

```
##           UkRegion EastWestFlag Freq
## 1        Hampshire         East  164
## 2             Kent         East  142
## 3     Lincolnshire         East  137
## 4            Devon         East  127
## 5         Somerset         East  120
## 6       Derbyshire         East  109
## 7  North Yorkshire         East  109
## 8          Cumbria         East  108
## 9      Oxfordshire         East  107
## 10  Cambridgeshire         East  106
```

Top 10 English counties with the most shared place names from the **East Coast**:

```r
dplyr::filter(ukCounts, EastWestFlag == "West" & Freq > 10)[1:10,]
```

```
##           UkRegion EastWestFlag Freq
## 1  North Yorkshire         West   36
## 2       Derbyshire         West   35
## 3          Cumbria         West   34
## 4        Hampshire         West   34
## 5     Lincolnshire         West   33
## 6             Kent         West   27
## 7          Norfolk         West   27
## 8       Shropshire         West   26
## 9            Devon         West   25
## 10         Suffolk         West   25
```

## 4. Power BI {.tabset .tabset-fade .tabset-pills}
### a. Importing R code

One of the benefits of using more recent versions of Power BI is being able to use the R integration tools available to you. For example, I can create datasets within a report by simply copying and pasting the R (and SQL) queries we've written so far.

![Power BI will determine which variables are tables and incorporate them into your Power BI report file.](images/eg_input.png)

The script can be concatenated together and pasted in the **R script** option of the **Get Data tab**.

```
#### Install relevant libraries beforehand and load them.
library(data.table)
library(dplyr)
library(sqldf) # install.packages(c("sqldf","dplyr","data.table"))

# Import the data.
citiesDataFull <- fread("C:\\OF\\DLG\\R Project\\data\\Cities_ProcessedOutput.csv")

# Australia
aus <- sqldf::sqldf("
  SELECT
      AccentCity, 
      Region,
      Longitude, Latitude
  FROM 
      citiesDataFull aus
  WHERE
    AccentCity IN 
      (SELECT DISTINCT AccentCity FROM citiesDataFull WHERE Country = 'gb')
  AND
    Country = 'au'")

# India
india <- sqldf::sqldf("
  SELECT
      AccentCity, 
      Region,
      Longitude, Latitude
  FROM 
      citiesDataFull ind
  WHERE
    ind.AccentCity IN 
      (SELECT DISTINCT AccentCity FROM citiesDataFull WHERE Country = 'gb')
  AND
    ind.Country = 'in'")
####  ....
```
### b. The Power BI report.
I have attached a Power BI file with Power BI reports attached. **You will need the latest version of Power BI Desktop in order to view it.**

![A preview of a Power BI report.](images/eg_dashboard.png)

## 5. Conclusions and notes. {.tabset .tabset-fade .tabset-pills}
### a. Conclusion 
**That the hypothesis is true** - there are indeed more places with UK names on the East Coast than there are on the West Coast.

### b. Improvements.

Given a longer time frame to work in, there are a few extra hypotheses I would have liked to have investigated:

- **How did the number of shared names change over time?** With additional data (either scraped from an external source or from a readymade dataset) could we map the colonisation of the East and West coasts and observe the population of cities over years?
- **Greater accuracy in the data** Given some extra time to research, I would improve this piece by sourcing a more accurate list of UK cities, perhaps from the Office of National Statistics or from Ordanance Survey, to more accurately measure the number of exact matches of UK names to US names.
- **Fuzzy matching** It would be interesting to introduce Levenshtein distances into future analyses to try and match on similar sounding names to provide a workaround for name variations (such as Sutton-on-the-Hill and Sutton-on-Hull)
- **Compensating for the multiple longitude/latitude values** I would have liked to have incorporated a function from a Stack Overflow question I answered a while ago, which aggregates long/lat values taking into account the curviture of the Earth. Alas, the code is below::

## 6. References {.tabset .tabset-fade .tabset-pills}

Main dataset: <http://download.maxmind.com/download/worldcities/worldcitiespop.txt.gz>

Region codes for the main dataset: <http://www.maxmind.com/download/geoip/misc/region_codes.csv>

Reference for east and west coast definitions: <https://en.wikipedia.org/wiki/East_Coast_of_the_United_States>

<https://en.wikipedia.org/wiki/West_Coast_of_the_United_States>
