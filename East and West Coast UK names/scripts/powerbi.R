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

# East coast
muricaEast <- sqldf::sqldf("
                           SELECT
                           AccentCity, 
                           Region,
                           Longitude, Latitude
                           FROM 
                           citiesDataFull usa
                           WHERE
                           usa.AccentCity IN 
                           (SELECT DISTINCT AccentCity FROM citiesDataFull WHERE Country = 'gb')
                           AND
                           usa.Country = 'us' AND usa.EastWestFlag = 'East'")

# West coast
muricaWest <- sqldf::sqldf("
                           SELECT
                           AccentCity, 
                           Region,
                           Longitude, Latitude
                           FROM 
                           citiesDataFull usa
                           WHERE
                           usa.AccentCity IN 
                           (SELECT DISTINCT AccentCity FROM citiesDataFull WHERE Country = 'gb')
                           AND
                           usa.Country = 'us' AND usa.EastWestFlag = 'West'")


# State counts
eastCounts <- data.frame(table(muricaEast$Region))
westCounts <- data.frame(table(muricaWest$Region))

# UK county counts.
ukCounts <- sqldf::sqldf("
                         SELECT
                         'United Kingdom' as Location,
                         uk.Region as UkRegion,
                         usa.EastWestFlag as EastWestFlag,
                         count(1) as Freq
                         FROM 
                         (SELECT AccentCity, Region, EastWestFlag FROM citiesDataFull WHERE Country = 'us' AND EastWestFlag != 'Other') usa 
                         INNER JOIN 
                         (SELECT AccentCity, Region FROM citiesDataFull WHERE Country = 'gb') uk 
                         ON 
                         usa.AccentCity = uk.AccentCity 
                         GROUP BY
                         'United Kingdom', uk.Region, usa.EastWestFlag
                         ORDER BY
                         Freq DESC")