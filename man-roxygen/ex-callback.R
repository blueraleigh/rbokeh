## range

# console callback
figure() %>%
  ly_points(1:10) %>%
  x_range(callback = console_callback()) %>%
  y_range(callback = console_callback())

# debug callback
figure() %>%
  ly_points(1:10) %>%
  x_range(callback = debug_callback())

# character callback
figure() %>%
  ly_points(1:10) %>%
  x_range(callback = "console.log('hi')")


## hover

# console callback (prints cb_data and cb_obj when hovered)
figure() %>%
  ly_points(1:10, lname = "points") %>%
  tool_hover(console_callback(), "points")

# debug callback (launches debugger)
figure() %>%
  ly_points(1:10, lname = "points") %>%
  tool_hover(debug_callback("points"), "points")

# just hover
figure() %>%
  ly_points(1:10, hover = data.frame(a = 1:10))

# both hover and hover callback
figure() %>%
  ly_points(1:10, hover = data.frame(a = 1:10), lname = "points") %>%
  tool_hover(console_callback(), "points")

# two different glyphs with different hover callbacks
figure() %>%
  ly_points(1:10, lname = "points1") %>%
  ly_points(2:12, lname = "points2") %>%
  tool_hover("if(cb_data.index['1d'].indices.length > 0) console.log('1')", "points1") %>%
  tool_hover("if(cb_data.index['1d'].indices.length > 0) console.log('2')", "points2")

# tool_hover with references to lnames made available callback
# is only triggered on l1 hover
figure() %>%
  ly_points(1:10, lname = "l1") %>%
  ly_points(2:11, lname = "l2") %>%
  tool_hover(debug_callback(c("l1", "l2")), "l1")


## tap

dd <- data.frame(x = 1:10, link = paste0("http://google.com#q=", 1:10))

# just url
figure() %>%
  ly_points(x, url = "@link", data = dd, lname = "points")

# console callback (prints cb_obj and cb_data (empty) when point is clicked)
figure() %>%
  ly_points(x, data = dd, lname = "points") %>%
  tool_tap(console_callback(), "points")

# debug callback
figure() %>%
  ly_points(x, data = dd, lname = "points") %>%
  tool_tap(debug_callback("points"), "points")

# both console and url (note that you can toggle which one in toolbar)
# but would be good to be able to do both
figure() %>%
  ly_points(x, url = "@link", data = dd, lname = "points") %>%
  tool_tap(console_callback(), "points")

# two layers both with different tap callback
# only first is honored (no matter what point is clicked)
# would be good if could do both
# https://github.com/bokeh/bokeh/issues/3804
figure() %>%
  ly_points(1:10, lname = "l1") %>%
  ly_points(2:11, lname = "l2") %>%
  tool_tap("console.log('l1')", "l1") %>%
  tool_tap("console.log('l2')", "l2")

## selection

figure(tools = "lasso_select") %>%
  ly_points(1:10, lname = "points") %>%
  tool_selection(debug_callback(), "points")

figure(tools = "box_select") %>%
  ly_points(1:10, lname = "points") %>%
  tool_selection(debug_callback(), "points")


# won't work when splitting up glyphs...
# figure() %>% ly_points(1:10, glyph = rep(c("a", "b"), 5))

## shiny example
##---------------------------------------------------------

\dontrun{
library("shiny")
library("rbokeh")
dat <- data.frame(x = rnorm(10), y = rnorm(10))

ui <- fluidPage(
  rbokehOutput("rbokeh", width = 500, height = 540),

  strong("x range change event:"),
  textOutput("x_range_text"),

  strong("y range change event:"),
  textOutput("y_range_text"),

  strong("hover event:"),
  textOutput("hover_text"),

  strong("triggered by tap/click:"),
  htmlOutput("tap_text"),

  strong("index of selected triggered by any selection:"),
  textOutput("selection_text")
)

server <- function(input, output, session) {
  output$rbokeh <- renderRbokeh({
    figure() %>% ly_points(x = x, y = y, data = dat,
      hover = list(x, y), lname = "points") %>%
      tool_hover(shiny_callback("hover_info"), "points") %>%
      tool_tap(shiny_callback("tap_info"), "points") %>%
      tool_box_select(shiny_callback("selection_info"), "points") %>%
      x_range(callback = shiny_callback("x_range")) %>%
      y_range(callback = shiny_callback("y_range"))
  })

  output$x_range_text <- reactive({
    xrng <- input$x_range
    if(!is.null(xrng)) {
      paste0("start: ", xrng$start, ", end: ", xrng$end)
    } else {
      "waiting for x-axis pan/zoom event (use pan/zoom to trigger)..."
    }
  })

  output$y_range_text <- reactive({
    yrng <- input$y_range
    if(!is.null(yrng)) {
      paste0("start: ", yrng$start,", end: ", yrng$end)
    } else {
      "waiting for y-axis pan/zoom event (use pan/zoom to trigger)..."
    }
  })

  output$hover_text <- reactive({
    hi <- input$hover_info
    if(!is.null(hi)) {
      paste0("index: ", hi$index[["1d"]]$indices, ", x: ",
        hi$geom$sx, ", y:", hi$geom$sy)
    } else {
      "waiting for hover event (hover over plot or points on plot to trigger)..."
    }
  })

  output$tap_text <- reactive({
    ti <- input$tap_info
    if(!is.null(ti)) {
      paste("index:", paste(ti, collapse = ", "))
    } else {
      "waiting for tap/click event (click point(s) to trigger)..."
    }
  })

  output$selection_text <- reactive({
    si <- input$selection_info
    if(!is.null(si)) {
      paste("index:", paste(si, collapse = ", "))
    } else {
      "waiting for selection event (click point(s) or use box select tool to trigger)..."
    }
  })
}

shinyApp(ui, server)
}
