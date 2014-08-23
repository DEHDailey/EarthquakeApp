## LoadQuakeData.R
## DEHDailey

## Retrieve data and make note of the time retrieved;
## use a default data set if retrieval fails
quakeURL <-'http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv'
defaultQuakes <- read.table( 'data/all_month.csv', sep=',', quote='"', header=TRUE, 
                             stringsAsFactors=FALSE, fill=TRUE, row.names=NULL )
defaultTime <- strftime( "2014-08-20 19:22:45", tz='GMT', usetz=TRUE )
## Try retrieving from the web
## Use a default data set if retrieval fails
try( {
  suppressWarnings( defaultQuakes <- read.csv( quakeURL, stringsAsFactors = FALSE, row.names=NULL ) )
  defaultTime <- strftime( Sys.time(), tz='GMT', usetz=TRUE)
}, silent=TRUE )
myCitation <- sprintf( "Global earthquakes over the last 30 days; data file was retrieved from %s on %s", 
                       quakeURL, defaultTime )

## Sort quakes by time, so later quakes will overplot earlier ones
defaultQuakes <- defaultQuakes[ order( defaultQuakes$time ), ]
