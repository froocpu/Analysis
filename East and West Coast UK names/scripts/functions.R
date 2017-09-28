## Store functions and pieces of useful code in a separate file to keep the analysis script tidy.
## Write a custom function for counting duplicates.
ufn_CountDuplicates <- function(x){
  return(nrow(x) - nrow(unique(x))) ## First column only for performance.
}

## Only get the libraries you need.
ufn_Library <- function(pkgs){
  installs = pkgs[!(pkgs %in% installed.packages()[,"Package"])]
  if(length(installs) > 0) {install.packages(installs)}
  lapply(pkgs, require, character.only = TRUE)
}
