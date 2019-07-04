# The Core Crime Data Plumber API, Right now it is very intensive, need to further break down

library(plumber)
library(dplyr)
library(jsonlite)
library(magrittr)
load("stl_crime/crimedb.rda")

#* @apiTitle STL Crime Data

#* Return JSON with Crimes
#* @param year The year crime occured
#* @param month The month crime occured
#* @param gun If 'true' filters for gun crime
#* @param coords Default WGS, else 'NAD_MO_EAST'
#* @param 
#* @json
#* @get /crime
function(year = "2019", month = "5", gun = "false", coords = "WGS") {
  year %<>% as.numeric()
  month %<>% as.numeric()

  crimedb %>%
    filter(year_occur == year) %>%
    filter(month_occur == month) -> f
  if(gun == "true"){
  f %<>% filter(gun_crime)
  }
  if(coords == "WGS"){
  f %<>% select(db_id, description, date_occur, ucr_category, wgs_x, wgs_y)
  }
  if(coords == "NAD_MO_EAST"){
  f %<>% select(db_id, description, date_occur, ucr_category, x_coord, y_coord)  
  }
  
  f %<>% toJSON()
  
  return(f)
}
