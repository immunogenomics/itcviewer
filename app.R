# Libraries -------------------------------------------------------------------

# Load packages, and install them if they are not installed.
if (!require(pacman)) { install.packages("pacman") }
pacman::p_load(
  "data.table",
  "ggplot2",
  "patchwork",
  "magrittr",
  "shiny",
  "shinyjs",
  "dplyr",
  "DT",
  "glue",
  "stringr",
  "scales",
  "tidyr",
  "seriation"
)
# devtools::install_github("thomasp85/patchwork")

# This is required if /srv/shiny-server is not owned by shiny:shiny
# See https://github.com/ropensci/plotly/issues/494
# pdf(NULL)

#

# Data ------------------------------------------------------------------------

source("R/load-data.R")

# Functions -------------------------------------------------------------------

source("R/plot-boxplot.R")
source("R/plot-umap.R")
source("R/plot-heatmap.R")
source("R/save-figure.R")
source("R/optimize-png.R")

which_numeric_cols <- function(dat) {
  which(sapply(seq(ncol(dat)), function(i) {
    is.numeric(dat[,i])
  }))
}

# library(ggvis)
# m %>%
#   ggvis(x = ~as.integer(cell_type), y = ~GENE, fill = ~cell_type) %>%
#   layer_boxplots(width = 0.5) %>%
#   add_axis("x", title = "", ticks = 0, properties = axis_props(
#     labels = list(fontSize = 20),
#     title = list(fontSize = 20)
#   )) %>%
#   add_axis("x", title = "", ticks = 7, properties = axis_props(
#     labels = list(fontSize = 20),
#     title = list(fontSize = 20)
#   )) %>%
#   add_axis("y", title = "Log2(TPM+1)", ticks = 5, properties = axis_props(
#     labels = list(fontSize = 20),
#     title = list(fontSize = 20)
#   )) %>%
#   hide_legend(scales = "fill")

#

# User interface --------------------------------------------------------------

# panel_one_gene <- tabPanel(
#   title = "One Gene",

ui <- fluidPage(
  useShinyjs(),
  extendShinyjs(script = "www/gene.js", functions = c("queryGene")),
  tags$head(
    tags$link(
      rel = "stylesheet", type = "text/css", href = "app.css"
    ),
    tags$link(rel="shortcut icon", href="favicon.ico"),
    tags$style("#rnaseq_one_gene{max-width:500px;}"),
    tags$style("#scrnaseq_umap{margin:auto;max-width:800px;}")
  ),
  # Application title
  navbarPage(
    title = "Innate T Cells",
    source(file.path("R", "ui-tab-data.R"), local = TRUE)$value
  ),
  HTML(
    "<footer class='myfooter page-footer'>
      <div class='text-center'>
      This website was created by <a href='https://slowkow.com'>Kamil Slowikowski</a>
      </div>
    </footer>"
  )
)

#

# Server ----------------------------------------------------------------------

server <- function(input, output, session) {
  
  this_gene <- one_gene_symbol_default
  grad_table_genes <- NULL
  
  # updateSelectizeInput(
  #   session = session,
  #   inputId = 'one_gene_symbol',
  #   choices = all_gene_symbols,
  #   server = TRUE
  # )
  
  output$grad_table <- DT::renderDataTable({
    grad_table <- grad %>%
      select(Gene = GENE_NAME, Beta, StdErr, Pvalue) %>%
      arrange(Pvalue) %>%
      head(nrow(grad))
    rownames(grad_table) <- 1:nrow(grad_table)
    grad_table_genes <<- grad_table$Gene
    numeric_cols <- colnames(grad_table)[which_numeric_cols(grad_table)]
    # Javascript-enabled table.
    DT::datatable(
      data = grad_table,
      options = list(
        "lengthChange" = FALSE,
        "orderClasses" = TRUE
      ),
      selection = "single"
    ) %>%
    DT::formatSignif(columns = numeric_cols, digits = 2)
  }, server = TRUE)
  
  # output$rnaseq_one_gene <- renderPlot({
  #   width  <- session$clientData$output_image_width
  #   grad_table_rowid <- input$grad_table_rows_selected
  #   if (length(grad_table_rowid)) {
  #     this_gene <- grad_table_genes[grad_table_rowid]
  #   }
  #   # else if (input$one_gene_symbol %in% all_gene_symbols) {
  #   #   this_gene <- input$one_gene_symbol
  #   # }
  #   # Query mygene.info
  #   js$queryGene(this_gene)
  #   if (this_gene %in% gene_symbols) {
  #     plot_boxplot(this_gene, 1.5)
  #   }
  # }, width = "auto", height = "auto")
  
  output$rnaseq_one_gene <- renderText({
    grad_table_rowid <- input$grad_table_rows_selected
    if (length(grad_table_rowid)) {
      this_gene <- grad_table_genes[grad_table_rowid]
    }
    # Query mygene.info
    js$queryGene(this_gene)
    if (this_gene %in% gene_symbols) {
      plot_boxplot(this_gene, 1.5)
    }
    retval <- "<div></div>"
    if (this_gene %in% gene_symbols) {
      retval <- save_figure(
        filename = glue("rnaseq_boxplot_{marker}.png", marker = this_gene),
        width = 6, height = 5, dpi = 300,
        html_alt = this_gene,
        ggplot_function = function() { plot_boxplot(this_gene) }
      )
    }
    retval
  })
  
  output$rnaseq_heatmap <- renderText({
    grad_table_rowid <- input$grad_table_rows_selected
    if (length(grad_table_rowid)) {
      this_gene <- grad_table_genes[grad_table_rowid]
    }
    retval <- "<div></div>"
    if (this_gene %in% gene_symbols) {
      retval <- save_figure(
        filename = glue("rnaseq_heatmap_{marker}.png", marker = this_gene),
        width = 9, height = 6, dpi = 300,
        html_alt = this_gene,
        html_style = "position:absolute; top:0; left:0; width:100%;",
        ggplot_function = function() { plot_heatmap(this_gene) }
      )
    }
    retval
  })
  
  # output$scrnaseq_umap <- renderPlot({
  #   width <- session$clientData$output_image_width
  #   grad_table_rowid <- input$grad_table_rows_selected
  #   if (length(grad_table_rowid)) {
  #     this_gene <- grad_table_genes[grad_table_rowid]
  #   }
  #   if (this_gene %in% rownames(s$log2cpm)) {
  #     s$meta$marker <- as.numeric(s$log2cpm[this_gene,])
  #     plot_umap(s$meta, title = this_gene)
  #   }
  # }, width = "auto", height = 500)
  
  output$scrnaseq_umap <- renderText({
    grad_table_rowid <- input$grad_table_rows_selected
    if (length(grad_table_rowid)) {
      this_gene <- grad_table_genes[grad_table_rowid]
    }
    retval <- glue(
      "<div class='alert alert-warning'>Fewer than 10 cells express <i>{gene}</i>.</div>",
      gene = this_gene
    )
    if (this_gene %in% rownames(s$log2cpm)) {
      s$meta$marker <- as.numeric(s$log2cpm[this_gene,])
      if (sum(s$meta$marker > 10)) {
        retval <- save_figure(
          filename = glue("scrnaseq_umap_{marker}.png", marker = this_gene),
          width = 10, height = 6, dpi = 300,
          html_alt = this_gene,
          html_style = "position:absolute; top:0; left:0; width:100%;",
          ggplot_function = function() { plot_umap(s$meta, title = this_gene) }
        )
      }
    }
    retval
  })
  
  # vis <- reactive({
  #   grad_table_rowid <- input$grad_table_rows_selected
  #   if (length(grad_table_rowid)) {
  #     this_gene <- grad_table_genes[grad_table_rowid]
  #   }
  #   # else if (input$one_gene_symbol %in% all_gene_symbols) {
  #   #   this_gene <- input$one_gene_symbol
  #   # }
  #   # Query mygene.info
  #   js$queryGene(this_gene)
  #   if (this_gene %in% gene_symbols) {
  #     plot_boxplot_ggvis(this_gene)
  #   }
  # })
  # vis %>% bind_shiny("rnaseq_one_gene")
}

#

# Launch the app --------------------------------------------------------------

shinyApp(ui = ui, server = server)

#
