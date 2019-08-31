# The Core Crime Data Plumber API

library(plumber)
library(dplyr)
library(jsonlite)
library(magrittr)
library(compstatr)
library(lubridate)
load("crimedb.rda")

#* @apiTitle STL Crime Data

#* Return coordinates of crimes
#* @param year The year crime occured
#* @param month The month crime occured
#* @param gun If 'true' filters for gun crime
#* @param coords Default WGS, else 'NAD_MO_EAST'
#* @param ucr Name of the crime, as it appears in the Inputs, else 'all'
#* @json
#* @get /coords
function(year = "2019", month = "June", gun = "false", coords = "WGS", ucr = "all") {
  # string manip
  year %<>% as.numeric()
  month <- which(month.name == month)

  # time (baseline) filtering
  crimedb %>%
    filter(year_occur == year) %>%
    filter(month_occur == month) -> f
  
  # gun filtering
  if(gun == "true"){
  f %<>% filter(gun_crime)
  }
  
  # ucr filtering
  if(ucr == "all"){NULL}
  else{
    ucr %<>% jsonlite::fromJSON()
    f %<>% filter(ucr_category %in% ucr)
  }
  
  # coordinate selection
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
  # string manip
  year %<>% as.numeric()
  month <- which(month.name == month)
  
  # time (baseline) filtering
  crimedb %>%
    filter(year_occur == year) %>%
    filter(month_occur == month) -> f
  
  # gun filtering
  if(gun == "true"){
    f %<>% filter(gun_crime)
  }
  
  # summary information 
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
  # string manip
  year %<>% as.numeric()
  month <- which(month.name == month)
  
  # time (baseline) filtering
  crimedb %>%
    filter(year_occur == year) %>%
    filter(month_occur == month) -> f
  
  # gun filtering
  if(gun == "true"){
    f %<>% filter(gun_crime)
  }
  
  # summary information
  f %<>% 
    group_by(district, ucr_category) %>%
    summarise(Incidents = n())
  
  return(f)  
  
}

#* Get monthly category summary
#* @param categories json vector containing ucr categories
#* @json
#* @get /catsum

function(categories = '["Homicide"]'){
  categories %<>% fromJSON
  crimedb %>%
    filter(ucr_category %in% categories) -> f
  f %<>% group_by(month_occur, year_occur, ucr_category) %>%
    summarise(Records = n())
    
  return(f)
}

#* Get coords for a specified range of time
#* @param start The start date for data (Inclusive)
#* @param end The end date for data (Inclusive) If left empty, will return just data from the start date
#* @param gun If 'true' filters for gun crime
#* @param coords Default WGS, else 'NAD_MO_EAST'
#* @param ucr Name of the crime, as it appears in the Inputs, else 'all'
#* @json
#* @get /range
function(start, end = "", gun = "false", coords = "WGS", ucr = "all") {
  # string manip
  year %<>% as.numeric()
  month <- which(month.name == month)
  
  if(end == ""){
    end = start
  }
  
  # time (baseline) filtering
  crimedb %>%
    filter(date_occur >= start) %>%
    filter(date_occur <= end) -> f
  
  # gun filtering
  if(gun == "true"){
    f %<>% filter(gun_crime)
  }
  
  # ucr filtering
  if(ucr == "all"){NULL}
  else{
    ucr %<>% jsonlite::fromJSON()
    f %<>% filter(ucr_category %in% ucr)
  }
  
  # coordinate selection
  if(coords == "WGS"){
    f %<>% select(db_id, ucr_category, wgs_x, wgs_y)
  }
  if(coords == "NAD_MO_EAST"){
    f %<>% select(db_id, ucr_category, x_coord, y_coord)  
  }
  
  return(f)
}
