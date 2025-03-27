# Dockerfile
FROM rocker/shiny-verse:latest

# Install additional R packages 
# (Add or remove packages as you need)
RUN R -e "install.packages(c('dplyr', 'ggplot2', 'ggrepel', 'rhandsontable'), repos='https://cloud.r-project.org')"

# Copy your Shiny app code into the image 
# (Assuming your app is in /YOUR-REPO/ )
COPY . /srv/shiny-server/app

# By default, rocker/shiny-verse uses shiny user, 
# and the default Shiny Server config points to /srv/shiny-server/
# We'll put our app in /srv/shiny-server/app
# Shiny Server listens on port 3838 by default.

EXPOSE 3838

# Container will launch Shiny Server automatically 
# from the base image's CMD. So no need to override CMD.
