# automatic scraping

# read last month in database

load("crimedb.rda")

# get current available month

a = RCurl::httpGET("api.bransonf.com/stlcrime/latest")
year  <- strsplit(a, "\\D{1,}")[[1]][2]
month <- strsplit(strsplit(a, "\\d{1,}")[[1]][1],"\\d{1,}")

# if current != last, scrape

# parse, but if fail send text message