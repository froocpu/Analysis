## Store definitions and input parameters in a separate script to keep the project tidy.
## Define the East/West coast states.
input_eastCoastStates <- c("Maine", "New Hampshire", "Massachusetts", "Rhode Island", 
                     "Connecticut", "New York", "New Jersey","Delaware", "Maryland", 
                     "Virginia", "North Carolina", "South Carolina", "Georgia", "Florida")

input_westCoastStates <- c("California","Oregon","Washington","Alaska","Hawaii")

## Create a lookup data table from the result.
input_EastWestLookup <- data.table(
  State = c(input_eastCoastStates, input_westCoastStates),
  EastWest = c(rep("East", length(input_eastCoastStates)), rep("West", length(input_westCoastStates)))
)

## Specify the country codes you are interested in bringing through analyse and place on the dashboard.
input_colonyCountries <- c("gb","us","au","in") 

## Where is the data?
input_cities <- "data/worldcitiespop.txt"