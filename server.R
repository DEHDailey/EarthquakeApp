## server.R
## Shiny app for accessing, plotting, and filtering earthquake data
## DEHDailey

library( maps )
library( mapproj )

source( 'LoadQuakeData.R' )

shinyServer( function( input, output, session ){
  ## 'session' needed above for updateSliderInput() below
  
  inMagRange <- reactive({ 
    with( defaultQuakes, 
          mag >= min( input$magSlider ) &
            mag <= max( input$magSlider ) )
  })
  
  inDepthRange <- reactive({
    with( defaultQuakes, 
          depth >= min( input$depthSlider ) & 
            depth <= max( input$depthSlider ) )
  })
  
  inLatRange <- reactive({
    with( defaultQuakes, 
          latitude >= min( input$latSlider ) & 
            latitude <= max( input$latSlider ))
  })
  
  inLongRange <- reactive({
    with( defaultQuakes, 
          longitude >= min( input$longSlider ) &
            longitude <= max( input$longSlider ) )
  })
  
  selectedEvents <- reactive( { inMagRange()     & 
                                  inDepthRange() &
                                  inLatRange()   &
                                  inLongRange()  } )
  
  latRange  <- reactive( { 
    ## Checks if slider is a single value and fixes it if needed.
    rr <- range( input$latSlider )
    if( diff( rr ) != 0 ) return( range( input$latSlider ) )
    if( max( rr ) < 90 ) {
      updateSliderInput( session, 'latSlider', value=c( NA, max( rr ) + 5 ) )
      return( range( input$latSlider ) )
    } else {
      updateSliderInput( session, 'latSlider', value=c( min(rr ) - 5, NA ) )
      return( range( input$latSlider ) )
    }
    
    } )
  longRange <- reactive( { 
    ## Checks if slider is a single value and fixes it if needed.
    rr <- range( input$longSlider )
    if( diff( rr ) != 0 ) return( range( input$longSlider ) )
    if( max( rr ) < 180 ) {
      updateSliderInput( session, 'longSlider', value=c( NA, max( rr ) + 5 ) )
      return( range( input$longSlider ) )
    } else {
      updateSliderInput( session, 'longSlider', value=c( min(rr ) - 5, NA ) )
      return( range( input$longSlider ) )
    }
    
  } )
  
  clickedInMap <- reactive({
    if( is.null( input$mapLocation ) ) return( FALSE )
    if( input$mapLocation$x < min( longRange() ) | input$mapLocation$x > max( longRange() ) ) return( FALSE )
    if( input$mapLocation$y < min( latRange() )  | input$mapLocation$y > max( latRange() ) ) return( FALSE )
    return( TRUE )
  })
  
  output$numEvents <- renderText({
    sprintf( "Events in current data file: %d", nrow( defaultQuakes ) )
  })
  
  output$eventsShown <- renderText({
    sprintf( 'Events shown in current map: %d', sum( selectedEvents() ) )
  })
  
  output$excludeLocation <- renderText({
    sprintf( "Events excluded by lat/long: %d", sum( !inLatRange() | !inLongRange() ) )
  })
  
  output$excludeMagnitude <- renderText({
    sprintf( "Events excluded by magnitude selection: %d", sum( !inMagRange() ) )
  })
  
  output$excludeDepth <- renderText({
    sprintf( "Events excluded by depth selection: %d", sum( !inDepthRange() ) )
  })

  output$citation <- renderText({
    myCitation
  })
  
  output$plot <- renderPlot( {
  
    par( bg='lightyellow' )
    depthColors <- rainbow( 50 )[as.numeric( cut( defaultQuakes$depth, breaks=seq( 0, 1000, by=50 ),
                                                  include.lowest=TRUE ) ) ]
    
    myQuakes <- defaultQuakes[ selectedEvents(), ]
    myColors <- depthColors[ selectedEvents() ]
    
    tryCatch ( {
      map( database = 'world', interior=FALSE, fill=TRUE, col='gray',
#         bg='coral',
         xlim=longRange(),
         ylim=latRange() )
      map.axes() },
      error = function( e ) {
#        par( bg='coral' )
        ## Error handling in case lat/long sliders are compressed to a single value
        if( diff( range( input$latSlider ) ) == 0 ) return()
        if( diff( range( input$longSlider )) == 0 ) return()
        
        plot( 0, 0, type='n', # asp=1,
              xlim=longRange(), xlab='',
              ylim=latRange(), ylab='',
              sub='No plottable land masses in selected region; using alternate plotting method' )
      }
      )

    with( myQuakes, points( longitude, latitude, 
                            pch=21, cex = 3*log10(1.01+mag),
                            bg=myColors,
                            col='darkgray') )
    if( clickedInMap() ) {
      points( input$mapLocation, pch=3, cex=5, lwd=0.3, col='#0000FF77' )
      rect( input$mapLocation$x - 15,
            input$mapLocation$y - 15,
            input$mapLocation$x + 15,
            input$mapLocation$y + 15,
            border = '#0000FF77',
            col='#0000FF0F')
    }
    })
  
  output$clickLocations <- renderText({
    if( is.null( input$mapLocation ) ) return( sprintf( "Click a location in the map for details of nearby events." ) )
    
    outOfRange <- input$mapLocation$x < min( input$longSlider ) |
                  input$mapLocation$x > max( input$longSlider ) |
                  input$mapLocation$y < min( input$latSlider ) |
                  input$mapLocation$y > max( input$latSlider )
    if( outOfRange ) return( "Most recent clicked location is outside the bounds of the current map." )
    
    return( sprintf( "Table shows events matching mag/depth selections and nearest to clicked location: Longitude %d, Latitude %d", 
                     round( input$mapLocation$x ), round( input$mapLocation$y ) ) )
  })
  
  output$nearbyTable <- renderTable( {
    if( is.null( input$mapLocation ) ) return( NULL )
    if( !clickedInMap() ) return( NULL )
    
    ## Filtered events within +/- 15 degrees (lat and long) from clicked point
    myLong <- input$mapLocation$x
    nearbyLong <- abs( defaultQuakes$longitude - myLong ) <= 15
    
    myLat  <- input$mapLocation$y
    nearbyLat <- abs( defaultQuakes$latitude - myLat ) <= 15
    
    nearbyEvents <- defaultQuakes[ 
      ( nearbyLong & nearbyLat ) &
      ( inMagRange() & inDepthRange() ), ]
    
    ## Calculate rough distances only for these "nearby" events
    distances <- sqrt( ( nearbyEvents$longitude - myLong ) ^ 2 +
                       ( nearbyEvents$latitude  - myLat  ) ^ 2 )
    nearbyEvents <- nearbyEvents[ order( distances ), ]
    
    nearbyTable <- head( nearbyEvents[, c( 'time', 'latitude', 'longitude', 'depth', 'mag', 'place' )] )
    
    if( nrow( nearbyTable ) == 0 ) return( matrix( 'No events matching selections within +/- 15 degrees latitude or longitude.' ) )
    
    return( nearbyTable )
  } )
  
})
