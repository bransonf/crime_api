FROM rocker/r-ver:3.6.0

MAINTAINER Branson Fox <bransonf@wustl.edu>

# linux depedencies for R packages
RUN apt-get update && apt-get install -y \
	libudunits2-0 \
	libudunits2-dev \
	libgdal-dev \
	libssl-dev \
	libcurl4-openssl-dev \
	libcairo2-dev


# install R libraries
RUN R -e "install.packages(c('plumber','dplyr','jsonlite','magrittr','lubridate','remotes'))"
RUN R -e "remotes::install_github('slu-openGIS/compstatr')"

# copy the api script to the server
RUN mkdir -p /var/plumber/stl_crime
COPY stl_crime/* /var/plumber/stl_crime/
WORKDIR /var/plumber/stl_crime/

EXPOSE 8000

CMD ["R", "-e", "plumber::plumb('plumber.R')$run(host = '0.0.0.0', port = 8000, swagger = FALSE)"]