#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com/
#

rsconnect::setAccountInfo(name='syedmfuad',
                          token='C16227CE2D30F2CB94FE3085F7103D3C',
                          secret='D2OPsla/YSKmuTeHL6CWFBI5GEkoHgWLaZB2P8Y2')

library(shiny)
library(ggplot2)
library(tidyverse)
library(tidyquant)
library(timetk)
library(scales)
library(Quandl)
library(dplyr)
library(quantmod)
library(purrr)
library(PerformanceAnalytics)
library(pspline)
library(hrbrthemes)
library(mvmeta)

ui <- fluidPage(
  titlePanel("Volatility Regime"),
    
  fluidRow(
    column(2, ailgn="center",
           textInput("stocks", "Stocks", "MSFT AAPL")),
    column(2,
           textInput("w", "Portf. %", "25 75"))),
  
  fluidRow(
    column(2, ailgn="center",
           numericInput("breakpoint", "Number of breakpoints", 5, min = 1, max = 100))),
  
  fluidRow(
    column(4, ailgn="center",
           dateRangeInput("date", "Date range", start="2013-01-01", end=as.character(Sys.Date())))),
  
  fluidRow(
    column(4, ailgn="center",
           selectInput("rebalance", "Rebalancing period", choices=list("Yearly"="years", "Quarterly"="quarters",
                                                                       "Monthly"="months", "Weekly"="weeks",
                                                                       "Daily"="days"), selected="months"))),
  
  fluidRow(
    column(4, ailgn="center",
           selectInput("ret_chain", "Return chaining", choices=list("Simple"="discrete", "Log"="log"), 
                       selected="discrete"))),
  
  actionButton("go", "Get Charts", class="btn-primary"),
  
  mainPanel(
    tabsetPanel(
      tabPanel("Cumulative returns", plotOutput("plot3")),
      tabPanel("Cumulative squared returns", plotOutput("plot2")),
      tabPanel("Volatility regimes", plotOutput("plot1"))
    )
  )
)

server <- function(input, output){
  returns_adj <- eventReactive(input$go, {
    
    tickers <- input$stocks
    tickers <- strsplit(as.character(tickers), " ")
    tickers <- unlist(tickers)
    
    w <- input$w
    w <- strsplit(as.character(w), " ")
    w <- unlist(w)
    w <- as.numeric(w)
    w <- w/100
    
    GetMySymbols <- function(x){getSymbols(x,
                                           src="yahoo",
                                           from=input$date[1],
                                           to=input$date[2],
                                           auto.assign=FALSE)}

    adj_prices <- map(tickers, GetMySymbols) %>% map(Ad) %>% reduce(merge.xts) %>%
      to.monthly(indexAt="lastof", OHLC=FALSE) %>% `colnames<-` (tickers) %>%
      Return.calculate(method=input$ret_chain) %>% na.omit() 
    
    adj_returns_port <- Return.portfolio(adj_prices, weights=w, rebalance_on=input$rebalance) %>% 
      as.data.frame()
    
    adj_returns_port
  })
  
  dataChart1 <- reactive({

    chart1 <- returns_adj()
    chart1$port_returnsq_cr <- cumprod(1+(chart1$portfolio.returns)**2)-1
    chart1$port_return_cr <- cumprod(1+(chart1$portfolio.returns))
    chart1$date <- rownames(chart1)
    chart1$date <- as.Date(chart1$date, format = "%Y-%m-%d")
    chart1
    
  })
    
  dataChart2 <- reactive({
    
    chart2 <- dataChart1()
    chart2$ID <- seq.int(nrow(chart2))
    #chart2 <- as.data.frame(chart2)
    #chart2$date <- rownames(chart2)
    fit_lm <- lm(port_returnsq_cr ~ 1 + ID, data=chart2)
    fit_segmented <- segmented::segmented(fit_lm, seg.Z=~ID, npsi=input$breakpoint)
    df <- data.frame(y=fit_segmented$fitted.values, x = seq.int(length(fit_segmented$fitted.values)))
    date=as.Date(chart2$date, format = "%Y-%m-%d")
    date <- date[-1]
    sd <- sqrt(12*(diff(df$y)/diff(df$x)))
    df_i_want <- data.frame(sd, date)
    
    df_i_want
  })
  
  output$plot3 <- renderPlot({
    ggplot(data=dataChart1(), aes(x=date, y=port_return_cr)) + geom_line(size=1, group=1, color="#69b3a2") +
      labs(title = paste0('Cumulative squared return of portfolio with tickers: "', input$stocks,'"'),
           subtitle = paste0('Months ', format(dataChart1()$date[1], '%Y-%m'), ' to ', 
                             format(dataChart1()$date[nrow(dataChart1())], '%Y-%m')),
           x="Date", y="Cumulative return", caption="Source: Yahoo API")
  })
  
  output$plot2 <- renderPlot({
    ggplot(data=dataChart1(), aes(x=date, y=port_returnsq_cr)) + geom_line(size=1, group=1, color="#69b3a2") +
      labs(title = paste0('Cumulative squared return of portfolio with tickers: "', input$stocks,'"'),
           subtitle = paste0('Months ', format(dataChart1()$date[1], '%Y-%m'), ' to ', 
                             format(dataChart1()$date[nrow(dataChart1())], '%Y-%m')),
           x="Date", y="Cumulative squared return", caption="Source: Yahoo API")
  })
    
    output$plot1 <- renderPlot({
      ggplot(data=dataChart2(), aes(x=date, y=sd)) + geom_line(size=1, group=1, color="#69b3a2") + 
        geom_area(fill="#69b3a2", alpha=0.4) +
        labs(title = paste0('Volatility regime of portfolio with tickers: "', input$stocks,'"'),
             subtitle = paste0('Months ', format(dataChart1()$date[1], '%Y-%m'), ' to ', 
                               format(dataChart1()$date[nrow(dataChart2())], '%Y-%m')),
          x="Date", y="Annualized standard deviation", caption="Source: Yahoo API") #theme_ipsum() + 
    })

}

# Run the application
shinyApp(ui = ui, server = server)

#p = ggplot() + geom_line(data = df_i_want, aes(x = x, y = sq), color = "turquoise3", size=4) +
  #geom_line(data = df_i_want, aes(x = x, y = y), color = "tomato", size=1.25) + 
  #labs(title = paste0("Volatility regime of ^GSPC"),
       #subtitle = paste0("Months 1985-02 to 2015-12"),
       #x="Index", y="Cumulative square return", caption="Source: Yahoo API")
