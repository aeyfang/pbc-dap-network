# ---- Load Libraries ----
library(shiny)
library(igraph)
library(dplyr)
library(visNetwork)
library(RColorBrewer)
library(purrr)

# ---- Load Data ----
significant_pairs <- read.csv("./results/networks/significant_pairs_unstrat.csv")
disease_frequencies <- read.csv("./data/frequencies/disease_frequencies_unstrat.csv")

# ---- Fixed Categories & Color Palette ----
fixed_categories <- c(
  "Eye", "Ear/Nose/Throat", "Mouth/Dental/Oral", "Skin", "Respiratory",
  "Gastrointestinal", "Bone/Orthopedic", "Cardiac",
  "Infection/Parasites", "Trauma", "Kidney/Urinary", "Other"
)

category_palette <- setNames(
  RColorBrewer::brewer.pal(length(fixed_categories), "Paired"),
  fixed_categories
)
category_palette["Kidney/Urinary"] <- "black"
category_palette["Other"] <- "gray50"
category_palette["Cross-category"] <- "grey38"

# ---- Label Replacements ----
label_replacements <- c(
  "Keratoconjunctivitis sicca (KCS)" = "Keratoconjunctivitis sicca",
  "Hypertension (high blood pressure)" = "Hypertension",
  "Lameness (chronic or recurrent)" = "Lameness",
  "Bordatella and/or parainfluenza (kennel cough)" = "Bordatella/parainfluenza",
  "Bordetella and/or parainfluenza (kennel cough)" = "Bordatella/parainfluenza",
  "Cushing's disease (hyperadrenocorticism; excess adrenal function)" = "Cushing's disease",
  "Addison's disease (hypoadrenocorticism; low adrenal function)" = "Addison's disease",
  "Diabetes mellitus (common diabetes which causes high blood sugar)" = "Diabetes mellitus",
  "Penetrating wound (such as a stick)" = "Penetrating wound",
  "Head trauma due to any cause" = "Head trauma",
  "Chronic or recurrent cough" = "Chronic/recurrent cough",
  "Chronic or recurrent bronchitis" = "Chronic/recurrent bronchitis",
  "Tracheal stenosis (narrowing)" = "Tracheal stenosis",
  "Dental calculus (yellow build-up on teeth)" = "Dental calculus",
  "Gingivitis (red, puffy gums)" = "Gingivitis",
  "Retained deciduous (baby) teeth" = "Retained deciduous teeth",
  "Hearing loss (incompletely deaf)" = "Hearing loss",
  "Urinary tract infection (chronic or recurrent)" = "Urinary tract infection",
  "Urinary crystals or stones in bladder or urethra" = "Urinary crystals/stones",
  "Alopecia (hair loss)" = "Alopecia",
  "Atopic dermatitis (atopy)" = "Atopic dermatitis",
  "Pruritis (itchy skin)" = "Pruritis",
  "Chronic or recurrent hot spots" = "Chronic/recurrent hot spots",
  "Chronic or recurrent skin infections" = "Chronic/recurrent skin infections",
  "Food or medicine allergies that affect the skin" = "Skin food/medicine allergies",
  "Food or medicine allergies" = "Gastrointestinal food/medicine allergies",
  "Chronic or recurrent diarrhea" = "Chronic/recurrent diarrhea",
  "Chronic or recurrent vomiting" = "Chronic/recurrent vomiting",
  "Hemorrhagic gastroenteritis (HGE) or stress colitis (acute)" = "Hemorrhagic gastroenteritis or stress colitis",
  "Seborrhea or seborrheic dermatitis (greasy skin)" = "Seborrhea or seborrheic dermatitis",
  "Chocolate" = "Chocolate consumption",
  "Grapes or raisins" = "Grape/raisin consumption"
)

# ---- Cleaning Function ----
clean_disease_name <- function(name) {
  if (startsWith(name, "condition_")) {
    return(sub("^condition_", "", name))
  } else if (startsWith(name, "hs_cancer_types_")) {
    code <- disease_frequencies %>%
      filter(Code.from.DAP.data == name) %>%
      pull(Numerical.Codes)
    return(if (length(code) == 0) name else as.character(code))
  }
  return(name)
}

# ---- Graph Preparation ----
formatted_significant_pairs <- significant_pairs %>%
  transmute(
    Disease1 = map_chr(Disease1, clean_disease_name),
    Disease2 = map_chr(Disease2, clean_disease_name)
  )

raw_graph <- graph_from_data_frame(formatted_significant_pairs, directed = FALSE)

V(raw_graph)$category <- disease_frequencies$Disease.Category[match(
  V(raw_graph)$name,
  as.character(disease_frequencies$Numerical.Codes)
)]
V(raw_graph)$category[is.na(V(raw_graph)$category)] <- "Other"
V(raw_graph)$category <- ifelse(
  V(raw_graph)$category %in% fixed_categories,
  V(raw_graph)$category,
  "Other"
)

V(raw_graph)$frequency <- disease_frequencies$frequency[match(
  V(raw_graph)$name,
  as.character(disease_frequencies$Numerical.Codes)
)]

# ---- Edge Category Assignment ----
node_cats <- V(raw_graph)$category
edge_pairs <- igraph::ends(raw_graph, E(raw_graph), names = FALSE)
edge_categories <- apply(edge_pairs, 1, function(pair) {
  cat1 <- node_cats[pair[1]]
  cat2 <- node_cats[pair[2]]
  if (cat1 == cat2) {
    if (cat1 %in% fixed_categories) cat1 else "Other"
  } else {
    "Cross-category"
  }
})
E(raw_graph)$edge_category <- edge_categories

# ---- Label Assignment ----
node_labels <- disease_frequencies$Disease.Name[match(
  V(raw_graph)$name,
  as.character(disease_frequencies$Numerical.Codes)
)]
node_labels <- dplyr::recode(node_labels, !!!label_replacements)

# ---- Nodes and Edges ----
nodes <- data.frame(
  id = V(raw_graph)$name,
  label = node_labels,
  group = V(raw_graph)$category,
  value = V(raw_graph)$frequency,
  title = paste0(
    "<b>Disease:</b> ", node_labels, "<br>",
    "<b>Frequency:</b> ", V(raw_graph)$frequency, "<br>",
    "<b>Category:</b> ", V(raw_graph)$category
  ),
  color.background = category_palette[V(raw_graph)$category],
  color.border = "black",
  font.size = 0
)

edges <- igraph::as_data_frame(raw_graph, what = "edges") %>%
  mutate(
    color = category_palette[edge_category],
    title = edge_category
  )

# ---- Zoom-Based Label Reveal ----
zoom_label_js <- "
function(params) {
  var zoomLevel = this.getScale();
  var newFontSize = (zoomLevel > 0.3) ? 18 : 0;

  var updatedNodes = this.body.data.nodes.get().map(function(node) {
    var updatedFont = Object.assign({}, node.font || {}, { size: newFontSize });
    return Object.assign({}, node, { font: updatedFont });
  });

  this.body.data.nodes.update(updatedNodes);
}
"

# ---- Subgraph Helper ----
get_subgraph_nodes <- function(graph, category) {
  selected_ids <- V(graph)$name[V(graph)$category == category]
  neighbor_ids <- unique(unlist(
    igraph::adjacent_vertices(graph, selected_ids, mode = "all")
  ))
  unique(c(selected_ids, V(graph)$name[neighbor_ids]))
}

# ---- UI ----
ui <- fluidPage(
  titlePanel("Interactive Disease Network"),
  sidebarLayout(
    sidebarPanel(
      selectizeInput(
        inputId = "focus_category",
        label = "Focus on Category Subgraph",
        choices = sort(unique(nodes$group)),
        selected = NULL,
        multiple = TRUE,
        options = list(placeholder = 'Select one or more categories...')
      ),
      actionButton("clear_category", "Clear Category Focus"),
      br(), br(),
      textOutput("node_count")
    ),
    mainPanel(
      visNetworkOutput("disease_network", height = "750px")
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {
  observeEvent(input$clear_category, {
    updateSelectizeInput(session, "focus_category", selected = character(0))
  })
 filtered_graph <- reactive({
    if (is.null(input$focus_category) || length(input$focus_category) == 0) {
      list(nodes = nodes, edges = edges)
    } else {
      all_focus_ids <- unlist(lapply(input$focus_category, function(cat) {
        get_subgraph_nodes(raw_graph, cat)
      }))
      unique_ids <- unique(all_focus_ids)
      list(
        nodes = nodes %>% filter(id %in% unique_ids),
        edges = edges %>% filter(from %in% unique_ids & to %in% unique_ids)
      )
    }
  })
  
  output$disease_network <- renderVisNetwork({
    display_nodes <- filtered_graph()$nodes
    display_edges <- filtered_graph()$edges
    
    visNetwork(display_nodes, display_edges) %>%
      visOptions(
        highlightNearest = TRUE,
        nodesIdSelection = list(enabled = TRUE, main = "Select by disease name")
      ) %>%
      visNodes(font = list(
        size = 0,
        background = "rgba(255,255,255,0.8)",
        strokeWidth = 1,
        strokeColor = "black"
      )) %>%
      visPhysics(
        solver = "forceAtlas2Based",
        forceAtlas2Based = list(
          gravitationalConstant = -50,
          centralGravity = 0.01,
          springLength = 100,
          springConstant = 0.05,
          damping = 0.4
        ),
        stabilization = list(enabled = TRUE, iterations = 200)
      ) %>%
      visInteraction(
        tooltipDelay = 0,
        hideEdgesOnDrag = FALSE,
        zoomView = TRUE,
        navigationButtons = TRUE
      ) %>%
      visLayout(randomSeed = 42) %>%
      visEvents(zoom = zoom_label_js)
  })
  
  output$node_count <- renderText({
    paste("Number of visible nodes:", nrow(filtered_graph()$nodes))
  })
}

# ---- Run App ----
shinyApp(ui, server)
