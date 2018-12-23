#---------------------------------------------------------------------#
#               Parts-Of-Speech Tagging App                               #
#---------------------------------------------------------------------#

#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(igraph)
library(ggraph)
library(ggplot2)
library(udpipe)
# Define ui function
ui <- shinyUI(fluidPage(
  
  # Application title
  
  titlePanel("Parts-Of-Speech Tagger"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      
      fileInput("file", label = h3("Upload text file"),multiple = FALSE),
      #fileInput("model", label = h3("Upload language model"), multiple = FALSE),
      selectInput("select", label = h3("Select box"), 
                  choices = list("English" = "english", "Spanish" = "spanish", "Hindi" = "hindi"), 
                  selected = "english"),
      checkboxGroupInput("PartsOfSpeech", label = h3("Select Parts Of Speech for COG"), 
                         choices = list("Adjective (ADJ)"= 'ADJ' , "Noun(NN)"='NOUN' , "Proper Noun(NNP)" = 'PROPN', "Adverb (RB)"='ADV', "Verb (VB)"='VERB'),
                         selected = c('ADJ','NOUN','PROPN')),
      submitButton(text = "Generate Graph", icon("refresh"))
      
    ),
    
    
    # Show a plot of the generated distribution
    mainPanel(
      #plotOutput("distPlot")
      tabsetPanel(type = "tabs",
                  
                  tabPanel("Overview",
                           h4(p("Data input")),
                           p("This app supports only Text values (.txt) data file.",align="justify"),
                           
                           p("This application generates a Co-occurrence Graph on basis of Parts of Speech selected")   ,
                           p("By Default, co-occurences of upto tri-grams if Noun, Adjective and Proper Noun will be displayed in the COG "),
                           br(),
                           h4('How to use this App'),
                           p('To use this app', 
                             span(strong("Upload text file that needs to be analysed")),
                             span(strong("Download the model from Github")),
                             
                             p(' Select the POS tagged words that you would like to visualise',
                               'and click Generate Graph and go to COG tab'))),
                  tabPanel("COG",
                           plotOutput('plotcog')
                  )
                  
                  
      )
    )
  )
))


# Define Server function
server <- shinyServer(function(input, output) {
  Dataset <- reactive({
    if (is.null(input$file)) { return(NULL) }
    else{
      Data <- readLines(input$file$datapath)
      str(Data)
      return(Data)
    }
  })
  
  Modelset <- reactive({
    
    x <- udpipe_download_model(language=input$select )
    ud_model <- udpipe_load_model(x$file_model)
    
    
    y <- udpipe_annotate(ud_model, Dataset()) #%>% as.data.frame() %>% head()
    y <- as.data.frame(y)
    return(y)
    
  })
  
  output$plotcog <- renderPlot({
    if (is.null(input$file)) { return(NULL) }
    else{
      text_colloc <- keywords_collocation(x = Modelset(),   
                                          term = "token",group = c("doc_id", "paragraph_id", "sentence_id"),
                                          ngram_max = 5) 
      
      text_cooc <- cooccurrence(
        x = subset(Modelset(), upos %in% c(input$PartsOfSpeech)), 
        term = "token", 
        group = c("doc_id", "paragraph_id", "sentence_id"))
      
      wordnetwork <- head(text_cooc, 30)
      wordnetwork <- igraph::graph_from_data_frame(wordnetwork) # needs edgelist in first 2 colms.
      ggraph(wordnetwork, layout = "fr") +  
        geom_edge_link(aes(width = cooc, edge_alpha = cooc), edge_colour = "orange") +  
        geom_node_text(aes(label = name), col = "darkgreen", size = 3) +
        theme_graph(base_family = "Arial Narrow") +  
        theme(legend.position = "none") +
        labs(title = "Cooccurrences within selected words distance")
    }
    
  })
  
})

shinyApp(ui = ui, server = server)