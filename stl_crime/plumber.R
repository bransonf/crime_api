# The Core Crime Data Plumber API, Right now it is very intensive, need to further break down

library(plumber)
library(dplyr)
library(jsonlite)
library(magrittr)
library(compstatr)
load("crimedb.rda")

#* @apiTitle STL Crime Data

#* Return coordinates of crimes
#* @param year The year crime occured
#* @param month The month crime occured
#* @param gun If 'true' filters for gun crime
#* @param coords Default WGS, else 'NAD_MO_EAST'
#* @param ucr Currently supports `part_one` or `all`
#* @json
#* @get /coords
function(year = "2019", month = "June", gun = "false", coords = "WGS", ucr = "all") {
  year %<>% as.numeric()
  month <- which(month.name == month)

  crimedb %>%
    filter(year_occur == year) %>%
    filter(month_occur == month) -> f
  if(gun == "true"){
  f %<>% filter(gun_crime)
  }
  
  if(ucr == "all"){NULL}
  else{
    
    f %<>% filter(ucr_category %in%)
  }
  
  if(coords == "WGS"){
  f %<>% select(db_id, ucr_category, wgs_x, wgs_y)
  }
  if(coords == "NAD_MO_EAST"){
  f %<>% select(db_id, ucr_category, x_coord, y_coord)  
  }
  
  return(f)
}

#* Return Latest Available Data Month
#* @json
#* @get /latest
function(){
  compstatr::cs_last_update()
}

#* Return JSON with detailed information about a crime
#* @param dbid The unique database identifier of a crime
#* @json
#* @get /crime
function(dbid) {
  crimedb %>% 
    filter(db_id == dbid) %>%
    select(-x_coord,-y_coord,-wgs_x,-wgs_y) -> f
  
  return(f)
}

#* Get monthly neighborhood summary
#* @param year The year crime occured
#* @param month The month crime occured
#* @param gun If 'true' filters for gun crime
#* @json
#* @get /nbhood
function(year = "2019", month = "June", gun = "false"){
  year %<>% as.numeric()
  month %<>% as.numeric()
  
  crimedb %>%
    filter(year_occur == year) %>%
    filter(month_occur == month) -> f
  if(gun == "true"){
    f %<>% filter(gun_crime)
  }
   
  f %<>% 
    group_by(neighborhood, ucr_category) %>%
    summarise(Incidents = n())
   
  return(f)  
}

#* Get monthly district summary
#* @param year The year crime occured
#* @param month The month crime occured
#* @param gun If 'true' filters for gun crime
#* @param 
#* @json
#* @get /district

function(year = "2019", month = "June", gun = "false"){
  year %<>% as.numeric()
  month %<>% as.numeric()
  
  crimedb %>%
    filter(year_occur == year) %>%
    filter(month_occur == month) -> f
  if(gun == "true"){
    f %<>% filter(gun_crime)
  }
  
  f %<>% 
    group_by(district, ucr_category) %>%
    summarise(Incidents = n())
  
  return(f)  
  
}




