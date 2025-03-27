#
# app.R
#
# Make sure you have installed these packages:
#install.packages(c("shiny", "dplyr", "ggplot2", "ggrepel", "rhandsontable", "shinyjqui"), lib = "/home/rstudio/R/aarch64-unknown-linux-gnu-library/4.3")
#
# app.R
#

# Required packages
library(shiny)
library(rhandsontable)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(shinyjqui)

ui <- fluidPage(
  # Basic styling (colors, etc.)
  tags$head(
    tags$style(HTML("
      body {
        background-color: #ffffff;
        color: #232323;
        font-family: Arial, sans-serif;
      }
      .title {
        background-color: #232323;
        color: #f7ed4a;
        padding: 10px;
        border-radius: 5px;
        margin-bottom: 20px;
      }
      .stats-box {
        background-color: #f7ed4a;
        color: #232323;
        padding: 15px;
        border-radius: 5px;
        margin-bottom: 20px;
      }
      .action-btn {
        background-color: #232323 !important;
        color: #f7ed4a !important;
        border: none;
      }
      .action-btn:hover {
        background-color: #f7ed4a !important;
        color: #232323 !important;
      }
    "))
  ),
  
  # Title Banner
  div(class = "title",
      fluidRow(
        column(10,
               h2("Jefferson STEAM Night!!!!!"),
               h1("What is data: Height vs. Wingspan")
        ),
        column(2, style = "text-align: right; padding-top: 10px;",
               tags$a(
                 href = "https://github.com/YOUR-USERNAME/YOUR-REPO",
                 target = "_blank",
                 icon("github"), " View on GitHub"
               )
        )
      )
  ),
  
  # Layout: 2 columns - spreadsheet on left, plot/summary on right
  fluidRow(
    # LEFT PANEL: Spreadsheet
    column(width = 4,
           h3("Data Entry"),
           p("Right-click cells to insert/delete rows. Enter label (optional), height, wingspan."),
           fluidRow(
             column(3, actionButton("incTableFont", "Font+", class = "action-btn")),
             column(3, actionButton("decTableFont", "Font-", class = "action-btn"))
           ),
           fluidRow(column(6, actionButton("addRows", "+ Add 10 Rows", class = "action-btn"))),
           br(),
           rHandsontableOutput("hot"),
    ),
    
    # RIGHT PANEL: Resizable Plot + Summary
    column(width = 8,
           h3("Plot"),
           actionButton("incPlotFont", "Font+", class = "action-btn"),
           actionButton("decPlotFont", "Font-", class = "action-btn"),
           br(), br(),
           jqui_resizable(
             plotOutput("scatterPlot", height = "450px"),
             options = list(minWidth = 200, minHeight = 200)
           ),
           br(), h3("Summary"),
           actionButton("incSummaryFont", "Font +", class = "action-btn"),
           actionButton("decSummaryFont", "Font -", class = "action-btn"),
           br(), br(),
           jqui_resizable(
             div(class = "stats-box", uiOutput("summaryStats")),
             options = list(minHeight = 150, minWidth = 200)
           )
    )
  )
)

server <- function(input, output, session) {
  sizes <- reactiveValues(
    table = 14,
    plot = 14,
    summary = 14
  )
  
  observeEvent(input$incTableFont, { sizes$table <- sizes$table + 1 })
  observeEvent(input$incPlotFont, { sizes$plot <- sizes$plot + 1 })
  observeEvent(input$incSummaryFont, { sizes$summary <- sizes$summary + 1 })
  observeEvent(input$decTableFont, { sizes$table <- sizes$table - 1 })
  observeEvent(input$decPlotFont, { sizes$plot <- sizes$plot - 1 })
  observeEvent(input$decSummaryFont, { sizes$summary <- sizes$summary - 1 })
  
  defaultData <- data.frame(
    Label = rep("", 10),
    Height = rnorm(10),
    Wingspan = rnorm(10),
    Group = sample(c("Kids", "Adults", "Hominids"), 10, replace = TRUE),
    stringsAsFactors = FALSE
  )
  values <- reactiveValues(data = defaultData)
  
  observeEvent(input$addRows, {
    newRows <- data.frame(
      Label = rep("", 10),
      Height = rep(NA_real_, 10),
      Wingspan = rep(NA_real_, 10),
      Group = rep(NA_character_, 10),
      stringsAsFactors = FALSE
    )
    values$data <- rbind(values$data, newRows)
  })
  
  output$hot <- renderRHandsontable({
    rhandsontable(values$data, rowHeaders = NULL) %>%
      hot_cols(
        renderer = htmlwidgets::JS(
          paste0(
            "function (instance, td, row, col, prop, value, cellProperties) {
               Handsontable.renderers.TextRenderer.apply(this, arguments);
               td.style.fontSize = '", sizes$table, "px';
             }"
          )
        )
      ) %>%
      hot_col("Group",
              type = 'dropdown',
              source = c("Kids", "Adults", "Hominids"))
  })
  
  observeEvent(input$hot, {
    newData <- hot_to_r(input$hot)
    if (!is.null(newData)) {
      values$data <- newData
    }
  })
  
  output$scatterPlot <- renderPlot({
    dat <- values$data %>%
      filter(!is.na(Height), !is.na(Wingspan))
    
    if(nrow(dat) == 0) return(NULL)
    
    ggplot(dat, aes(x = Height, y = Wingspan)) +
      geom_smooth(aes(group = Group), 
                  method = "lm", se = TRUE,
                  color = scales::alpha("black", .1), fill = "black", alpha = .05,
                  linetype = "dashed") +
      geom_point(color = scales::alpha("#232323", 1), aes(fill = Group), shape = 21,
                 size = 4) +
      scale_fill_manual(values = c("Kids" = scales::alpha("#f7ed4a", .7),
                                   "Adults" = scales::alpha("#f7a541", .7),
                                   "Hominids" = scales::alpha("#f78154", .7)))+
      theme_minimal(base_size = sizes$plot) +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "#cccccc")
      ) +
      labs(
        title = "Height vs. Wingspan",
        x = "Height (inches)",
        y = "Wingspan (inches)"
      ) +
      geom_text_repel(
        data = dat %>% filter(Label != ""),
        aes(label = Label),
        color = "#232323",
        size = 0.25 * sizes$plot,
        max.overlaps = 20
      )
  })
  
  output$summaryStats <- renderUI({
    div(style = paste0("font-size: ", sizes$summary, "px;"),
        {
          dat <- values$data %>% filter(!is.na(Height), !is.na(Wingspan))
          if(nrow(dat) == 0){
            return(tags$p("No valid data yet. Please enter Height and Wingspan in the spreadsheet."))
          }
          avgHeight <- mean(dat$Height)
          medianHeight <- median(dat$Height)
          avgWingspan <- mean(dat$Wingspan)
          medianWingspan <- median(dat$Wingspan)
          
          corVal <- if(nrow(dat) > 1) {
            round(cor(dat$Height, dat$Wingspan, use = "complete.obs"), 3)
          } else {
            NA
          }
          
          tagList(
            tags$p(paste0("Number of records: ", nrow(dat))),
            tags$p(paste0("Average Height: ", round(avgHeight, 2), " in")),
            tags$p(paste0("Median Height: ", round(medianHeight, 2), " in")),
            tags$p(paste0("Average Wingspan: ", round(avgWingspan, 2), " in")),
            tags$p(paste0("Median Wingspan: ", round(medianWingspan, 2), " in")),
            tags$p(paste0("Correlation (Height vs. Wingspan): ",
                          ifelse(is.na(corVal), "Not enough data", corVal)))
          )
        }
    )
  })
}

shinyApp(ui = ui, server = server)
