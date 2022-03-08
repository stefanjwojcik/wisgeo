# TODO:
# 1. UI for visualizing sales in a given county 

library(shiny)
library(leaflet)
library(RColorBrewer)

ui <- bootstrapPage(
    tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
    leafletOutput("map", width = "100%", height = "100%"),
    absolutePanel(top = 10, right = 10,
                  sliderInput("range", "Prices", min(parcels$ESTFMKVALUE), max(parcels$ESTFMKVALUE),
                              value = range(parcels$ESTFMKVALUE), step = 0.1
                  ),
                  selectInput("colors", "Color Scheme",
                              rownames(subset(brewer.pal.info, category %in% c("seq", "div")))
                  ),
                  selectInput("county", "County",
                              unique(parcels$CONAME))
                  ),
                  checkboxInput("legend", "Show legend", TRUE)
    )

server <- function(input, output, session) {
    
    # Reactive expression for the data subsetted to what the user selected
    filteredData <- reactive({
        parcels[parcels$ESTFMKVALUE >= input$range[1] & parcels$ESTFMKVALUE <= input$range[2] & parcels$CONAME == input$county,]
    })
    
    # This reactive expression represents the palette function,
    # which changes as the user makes selections in UI.
    colorpal <- reactive({
        colorNumeric(input$colors, parcels$ESTFMKVALUE)
    })
    
    output$map <- renderLeaflet({
        # Use leaflet() here, and only include aspects of the map that
        # won't need to change dynamically (at least, not unless the
        # entire map is being torn down and recreated).
        leaflet(parcels) %>% addTiles() %>%
            fitBounds(~min(LONGITUDE), ~min(LATITUDE), ~max(LONGITUDE), ~max(LATITUDE))
    })
    
    # Incremental changes to the map (in this case, replacing the
    # circles when a new color is chosen) should be performed in
    # an observer. Each independent set of things that can change
    # should be managed in its own observer.
    observe({
        pal <- colorpal()
        
        leafletProxy("map", data = filteredData()) %>%
            clearShapes() %>%
            addCircles(radius = ~log(ESTFMKVALUE+1)^2.5, weight = 1, color = "#777777",
                       fillColor = ~pal(ESTFMKVALUE), fillOpacity = 0.7, popup = ~paste(SITEADRESS, ESTFMKVALUE)
            )
    })
    
    # Use a separate observer to recreate the legend as needed.
    observe({
        proxy <- leafletProxy("map", data = parcels)
        
        # Remove any existing legend, and only if the legend is
        # enabled, create a new one.
        proxy %>% clearControls()
        if (input$legend) {
            pal <- colorpal()
            proxy %>% addLegend(position = "bottomright",
                                pal = pal, values = ~ESTFMKVALUE
            )
        }
    })
}

shinyApp(ui, server)

