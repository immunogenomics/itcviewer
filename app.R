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
  "stringr"
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
panel_one_gene <- fluidPage(
      h1("Innate T Cells"),
      h2("Explore gene expression along the T cell innateness gradient"),
      fluidRow(
        # column(width = 6, plotOutput("rnaseq_one_gene")),
        column(width = 6, htmlOutput("rnaseq_one_gene")),
        column(width = 6, DT::dataTableOutput("grad_table"))
      ),
      fluidRow(
        # column(width = 12, plotOutput("scrnaseq_umap"))
        column(
          width = 12,
          htmlOutput("scrnaseq_umap")
        )
      ),
      
      # hr(),
      # h2("Options"),
      # selectizeInput(
      #   inputId = 'one_gene_symbol',
      #   label = 'Gene:',
      #   choices = NULL,
      #   selected = 'TBX21',
      #   size = 10
      # ),
      
      # hr(),
      # fluidRow(
      #   plotOutput("rnaseq_one_gene")
      #   #ggvisOutput("rnaseq_one_gene")
      # ),
      
      br(),
      hr(),
      div(id = "geneinfo"),
      
      hr(),
      h2("About"),
      HTML(
        "<p>The data presented here comes from the laboratories of:
        <ul>
        <li><a href='https://connects.catalyst.harvard.edu/Profiles/display/Person/56904'>Dr. Patrick J. Brennan</a></li>
        <li><a href='https://immunogenomics.hms.harvard.edu/'>Dr. Soumya Raychaudhuri</a></li>
        <li><a href='https://www.hms.harvard.edu/dms/immunology/fac/Brenner.php'>Dr. Michael B. Brenner</a></li>
        </ul>
        </p>"
      ),
      HTML(
        "<p>Read our paper to learn more:</p>
        <p>
        <b>A genome-wide innateness gradient defines the functional state of human innate T cells.</b>
        Maria Gutierrez-Arcelus, Nikola Teslovich, Alex R Mola, Hyun Kim, Susan Hannes,
        Kamil Slowikowski, Gerald F. M. Watts, Michael Brenner, Soumya Raychaudhuri,
        Patrick J. Brennan. <i>bioRxiv</i> 2018.
        <a href='https://doi.org/10.1101/280370'>https://doi.org/10.1101/280370</a>
        </p>"
      ),
      h2("Contact"),
      p(
        "Please ",
        a("contact Dr. Maria Gutierrez", href = "mailto:mgutierr@broadinstitute.org"),
        " with any questions, requests, or comments."
      ),
      h2("Disclaimer"),
      # p(
      #   "Currently, this is private data intended to be shared internally,",
      #   " only with lab members (and reviewers)."
      # ),
      # p(
      #   strong(
      #     "Sharing any data from this site with anyone outside of the",
      #     " lab is prohibited."
      #   )
      # ),
      p(
        "The content of this site is",
        " subject to change at any time without notice. We hope that you",
        " find it useful, but we provide it 'as is' without warranty of",
        " any kind, express or implied."
      ),
      br()
      
    ) # fluidPage
# ) # tabPanel

panel_data <- tabPanel(
  title = "Home",
  panel_one_gene
)

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
    panel_data
  ),
  HTML(
    "<footer class='page-footer gray'>
      <div class='text-center' style='padding:1rem;background-color: #f8f8f8;'>
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
      "<div>Fewer than 10 cells express <i>{gene}</i>.</div>",
      gene = this_gene
    )
    if (this_gene %in% rownames(s$log2cpm)) {
      s$meta$marker <- as.numeric(s$log2cpm[this_gene,])
      if (sum(s$meta$marker > 10)) {
        retval <- save_figure(
          filename = glue("scrnaseq_umap_{marker}.png", marker = this_gene),
          width = 10, height = 6, dpi = 300,
          html_alt = this_gene,
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
