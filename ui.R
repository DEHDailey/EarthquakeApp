## ui.R
## Shiny app for accessing, plotting, and filtering earthquake data
## DEHDailey

defaults <- list(
  long = list( Min= -180, Max = 180, Start=c( -180, 180 ), Step = 5 ),
  lat  = list( Min = -90, Max = 90, Start = c( -90, 90 ), Step = 5 ),
  mag  = list( Min = -1, Max = 10, Start = c( 5, 10 ), Step = 1 ),
  dep  = list( Min = 0, Max = 1000, Start = c( 0, 1000 ), Step = 10 ) )

shinyUI( fluidPage(
  titlePanel( "Recent Earthquake Locations and Magnitudes" ),
  sidebarLayout(
    sidebarPanel(
      tags$head(
        tags$style("body {background-color: black; color: red}") ),
      h4( "Instructions" ),
          p( "Filter events by location, magnitude, and depth using the sliders below."),
          p( "Reload the app to reset all sliders."),
          textOutput( 'numEvents' ),
          textOutput( 'eventsShown' ),
        h4( "Location"),
          sliderInput( 'longSlider',
                       label=  'Show events in longitudes:',
                       min= defaults$long$Min, max=defaults$long$Max, 
                       value=defaults$long$Start,
                       step = defaults$long$Step ),
          sliderInput( 'latSlider',
                       label = 'Show events in latitudes:', 
                       min= defaults$lat$Min, max=defaults$lat$Max, 
                       value=defaults$lat$Start,
                       step = defaults$lat$Step ),
          textOutput( 'excludeLocation' ),
        h4( "Magnitude"),
          sliderInput( 'magSlider',
                       label = "Show events with magnitudes:",
                       min= defaults$mag$Min, max=defaults$mag$Max, 
                       value=defaults$mag$Start,
                       step = defaults$mag$Step ),
          textOutput( 'excludeMagnitude' ),
        
        h4( "Depth" ),
          ## I'd like to base the depth slider on the values in the dataset,
          ## but it is complicated to make the UI depend on data values-- the UI
          ## is loaded first and so cannot directly access the dataset.  Probably
          ## there is a workaround somewhere.
          sliderInput( 'depthSlider',
                       label = 'Show events at depths (km):',
                       min= defaults$dep$Min, max=defaults$dep$Max,
                       value=defaults$dep$Start,
                       step=defaults$dep$Step ),
          textOutput( 'excludeDepth' ),
        br(),
        p( 'Some events are excluded by multiple criteria.  See notes in main panel.' ),
      width=3),  ## End of sidebarPanel() call
    
    mainPanel(
      tags$head(
        tags$style("body {background-color: black; color: red}") ),
      p( 'If map does not appear, please wait for data to be retrieved...' ),
      textOutput( 'citation' ),
      h5( 'Click on map to show details of events near a selected location.' ),
      plotOutput( 'plot', clickId = 'mapLocation', height='600px' ),
      textOutput( 'clickLocations' ),
      tableOutput( 'nearbyTable' ),
      h3( 'Notes:' ),
      p( '* The Shiny server can be slow to draw and re-draw the map.  Please be patient.' ),
      p( '* The USGS data file is updated approximately every 15 minutes. This app uses a stored data file if it cannot access the USGS site.'),
      p( '* Magnitude is represented by size of plotted point.' ),
      p( '* Depth is represented by color of plotted point.  Red is closest to the surface.' ),
      p( '* Some depth values in database may be negative.  These events are omitted from the plot.'),
      p( '* Some events may be excluded by multiple criteria.',
         ' Therefore, the total of events excluded may exceed the number of events in the database.' ),
      p( '* As an example, set the longitude range to run from -115 to -110; the latitude range to ',
         'run from 40 to 45; the magnitude range to run from -1 to 10; and the depth range to run ', 
         'from 0 to 1000 km.  The cluster of events in the upper-right corner of the resulting map ',
         'shows the constant low-level sesmic activity near Yellowstone National Park in the USA.' ),
      width=9),  ## End of mainPanel() call
  
    position = 'right'
  )
)
)