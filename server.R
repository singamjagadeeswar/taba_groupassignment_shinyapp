# Shiny app created for Part of Speech Tagging 
# This app reads input file in the format .txt and using udpipe trained it creates co-occurances map based on user selection of options
# Noun, Propernoun, Verb, Adverb, Adjective

# this server side code of the app

# Include all the required libraries

library(shiny)
library(igraph)
library(ggraph)
library(ggplot2)
library(udpipe)


shinyServer(function(input, output) {
  
# Processes the input file given by user
    
  Dataset <- reactive({
    if (is.null(input$file)) { return(NULL) }
    else{
      Data <- readLines(input$file$datapath)
      str(Data)
      return(Data)
    }
  })
  
# Read the udpipe model as per language  
  Modelset <- reactive({
    
      x <- udpipe_download_model(language=input$select )
      ud_model <- udpipe_load_model(x$file_model)
     
      
      y <- udpipe_annotate(ud_model, Dataset()) #%>% as.data.frame() %>% head()
      y <- as.data.frame(y)
      return(y)
    
  })
   
# Plotting co-occurance plot  
  
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
