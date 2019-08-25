FROM rocker/r-ubuntu:18.04

MAINTAINER Branson Fox <bransonf@wustl.edu>

# linux depedencies for R packages
RUN apt-get update 

RUN apt-get install -y \
	libudunits2-0 \
	libudunits2-dev \
	libgdal-dev \
	libssl-dev \
	libcurl4-openssl-dev \
	libcairo2-dev \
	nginx \
	systemd

# configure system to serve plumber
RUN mkdir -p /var/plumber

RUN rm -f /etc/nginx/sites-enabled/default && \
    mkdir -p /var/certbot && \
    mkdir -p /etc/nginx/sites-available/plumber-apis/

COPY config/nginx.conf /etc/nginx/sites-available/plumber-apis/

RUN ln -sf /etc/nginx/sites-available/plumber /etc/nginx/sites-enabled/
RUN systemctl reload nginx

RUN ufw allow http && \
    ufw allow ssh && \
    ufw -f enable    

# install R libraries
RUN R -e "install.packages('plumber','dplyr','jsonlite','magrittr','lubridate'); remotes::install_github('slu-openGIS/compstatr')"

# copy the api script to the server
RUN mkdir -p /var/plumber/stl_crime
COPY stl_crime/plumber.R /var/plumber/stl_crime/

COPY config/service /etc/systemd/system/plumber-stl_crime.service
RUN systemctl daemon-reload
RUN systemctl start plumber-stl_crime && sleep 1
RUN systemctl restart plumber-stl_crime && sleep 1
RUN systemctl enable plumber-stl_crime
RUN systemctl status plumber-stl_crime

COPY config/conf /etc/nginx/sites-available/plumber-apis/stl_crime.conf
RUN systemctl reload nginx

EXPOSE 80
