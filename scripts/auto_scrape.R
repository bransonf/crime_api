# Scrape and standardize the data

  library(compstatr)
  library(dplyr)
  library(sf)
  library(lubridate)
  
  # Create Index of Available Data
  
  idx <- cs_create_index()
  crime_dta <- vector("list", 13)
  
  # get all years
  for (i in 1:13) {
    crime_dta[[i]] <- cs_get_data(year = (2008:2020)[i], index = idx)  
  }
  
  # fix the outliers
  # 1-5 all 18s
  for (i in 1:5) {
    crime_dta[[i]] <- cs_standardize(crime_dta[[i]], all, config = 18)
  }
  
  # 6 Jan - May July Aug 18s # Jun Sep-Dec 20
  crime_dta[[6]][["January"]]  <- cs_standardize(crime_dta[[6]], "January", config = 18)$January
  crime_dta[[6]][["February"]] <- cs_standardize(crime_dta[[6]], "February", config = 18)$February
  crime_dta[[6]][["March"]]    <- cs_standardize(crime_dta[[6]], "March", config = 18)$March
  crime_dta[[6]][["April"]]    <- cs_standardize(crime_dta[[6]], "April", config = 18)$April
  crime_dta[[6]][["May"]]      <- cs_standardize(crime_dta[[6]], "May", config = 18)$May
  crime_dta[[6]][["July"]]     <- cs_standardize(crime_dta[[6]], "July", config = 18)$July
  crime_dta[[6]][["August"]]   <- cs_standardize(crime_dta[[6]], "August", config = 18)$August
  
  # 10, May 26
  crime_dta[[10]][["May"]] <- cs_standardize(crime_dta[[10]], "May", config = 26)$May
  
  # build full dataset
  crime_dta <- lapply(crime_dta, dplyr::bind_rows)
  crimes08_19 <- dplyr::bind_rows(crime_dta)
  
  
  # add unique id for each row in Database
  crimes08_19 <- mutate(crimes08_19, db_id = row_number())
  
  # create fake sf for appending reprojected coordinates
  sf <- filter(crimes08_19, x_coord != 0 & y_coord != 0) %>% select(db_id, x_coord, y_coord)
  sf <- st_as_sf(sf, coords = c("x_coord", "y_coord"), crs = "+proj=tmerc +lat_0=35.83333333333334 +lon_0=-90.5 +k=0.9999333333333333 +x_0=250000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs 
") %>% st_transform(crs = 4326)
  sf <- mutate(sf, wgs_x = st_coordinates(sf)[,1],
               wgs_y = st_coordinates(sf)[,2])
  st_geometry(sf) <- NULL
  join <- left_join(crimes08_19, sf, by = "db_id")
  
  # coerce crime to numeric
  join <- mutate(join, crime = as.numeric(crime))
  
  # Add Vars for Easy querying
  crimedb <- mutate(join,
                        ucr_category = case_when(
                          between(crime, 10000, 19999) ~ "Homicide",
                          between(crime, 20000, 29999) ~ "Rape",
                          between(crime, 30000, 39999) ~ "Robbery",
                          between(crime, 40000, 49999) ~ "Aggravated Assault",
                          between(crime, 50000, 59999) ~ "Burglary",
                          between(crime, 60000, 69999) ~ "Larceny",
                          between(crime, 70000, 79999) ~ "Vehicle Theft",
                          between(crime, 80000, 89999) ~ "Arson",
                          between(crime, 90000, 99999) ~ "Simple Assault",
                          between(crime, 100000, 109999) ~ "Forgery",
                          between(crime, 110000, 119999) ~ "Fraud",
                          between(crime, 120000, 129999) ~ "Embezzlement",
                          between(crime, 130000, 139999) ~ "Stolen Property",
                          between(crime, 140000, 149999) ~ "Destruction of Property",
                          between(crime, 150000, 159999) ~ "Weapons Offense",
                          between(crime, 170000, 179999) ~ "Sex Offense",
                          between(crime, 180000, 189999) ~ "VMCSL",
                          between(crime, 200000, 209999) ~ "Offense Against Family",
                          between(crime, 210000, 219999) ~ "DWI/DUI",
                          between(crime, 220000, 229999) ~ "Liquor Laws",
                          between(crime, 240000, 249999) ~ "Disorderly Conduct",
                          between(crime, 250000, 259999) ~ "Loitering/Begging",
                          TRUE ~ "Other"
                          
                        ),
                        gun_crime = ifelse(crime == 10000 | (crime > 41000 & crime < 42000) | crime %in% c(31111, 31112,32111,32112,33111,34111,35111,35112,36112,37111,37112,38111,38112), TRUE, FALSE),
                        year_occur = lubridate::year(lubridate::mdy_hm(date_occur)),
                        month_occur = lubridate::month(lubridate::mdy_hm(date_occur)),
                        date_occur = as.Date(lubridate::mdy_hm(date_occur)))
  

  
  # Store in DB
  save(crimedb, file = "stl_crime/crimedb.rda")
