# Libraries -------------------------------------------------------------------

# Load packages, and install them if they are not installed.
if (!require(pacman)) { install.packages("pacman") }
pacman::p_load("shiny", "shinyjs", "dplyr")

#

# Data ------------------------------------------------------------------------

# Load: m log2cpm gene_symbols meta_colors
load("data/ITC_log2tpm_forShiny.rda")

# Mapping between Ensembl and Symbol
gene_symbols <- unlist(split(grad$GENE_NAME, grad$Row.names))

rownames(grad) <- grad$Row.names
grad$Row.names <- NULL

# Sanity check
stopifnot(all(m$sampleID == colnames(log2tpm)))

m$cell_type <- factor(
  x = m$cell_type,
  levels = c("CD4", "CD8", "MAIT", "NKT", "Vd1", "Vd2", "NK")
)

m_colors <- list(
  "cell_type" = c(
    "CD4" = "#0072B2",
    "CD8" = "#56B4E9",
    "MAIT" = "#009E73",
    "NKT" = "#CC79A7",
    "Vd1" = "#E69F00",
    "Vd2" = "#D55E00",
    "NK" = "#000000"
  )
)

# Just the symbols
all_gene_symbols <- unname(gene_symbols)

# The default gene to plot
one_gene_symbol_default = "TBX21"

font_size <- 20

#

# Functions -------------------------------------------------------------------

which_numeric_cols <- function(dat) {
  which(sapply(seq(ncol(dat)), function(i) {
    is.numeric(dat[,i])
  }))
}

plot_boxplot <- function(gene) {
  ensembl_id <- names(which(gene_symbols == gene))
  m$GENE <- as.numeric(log2tpm[ensembl_id,])
  gene_stats <- grad[ensembl_id,]
  par(mar = c(2.3, 4.6, 3.1, 0.1))
  boxplot(
    formula = GENE ~ cell_type,
    data = m,
    col = m_colors$cell_type,
    ylab = bquote("Log"[2]~"(TPM+1)"),
    # main = gene,
    main = sprintf(
      "%s\nP = %s, Beta = %s",
      gene, signif(gene_stats$Pvalue, 2), signif(gene_stats$Beta, 2)
    ),
    cex.names = 1.5,
    cex.lab = 1.5,
    cex.axis = 1.5,
    cex.main = 1.5
  )
  # legend(
  #   "topleft",
  #   legend = c(
  #     sprintf("P = %s", signif(gene_stats$Pvalue, 2)),
  #     sprintf("Beta = %s", signif(gene_stats$Beta, 2))
  #   ),
  #   bty = "n",
  #   cex = 1.5
  # )
}
#plot_boxplot("TBX21")

#

# User interface --------------------------------------------------------------

panel_about <- tabPanel(
  title = "About",
  mainPanel(
    h1("Innate T Cells"),
    p(
      "This data comes from the laboratories of",
      " Dr. Michael Brenner and Dr. Soumya Raychaudhuri."
    ),
    h2("Disclaimer"),
    p(
      "Currently, this is private data intended to be shared internally,",
      " only with lab members."
    ),
    p(
      strong(
        "Sharing any data from this site with anyone outside of the",
        " lab is prohibited."
      )
    ),
    p(
      "This website is an experiment in providing early access to",
      " preliminary data analysis results. The content of this site is",
      " subject to change at any time without notice. We hope that you",
      " find it useful, but we provide it 'as is' without warranty of",
      " any kind, express or implied."
    ),
    h2("Contact"),
    p(
      "Please ",
      a("contact us", href = "mailto:mgutierr@broadinstitute.org"),
      " us with any questions, requests, or comments."
    )
  )
)

panel_one_gene <- tabPanel(
  title = "One Gene",
    fluidPage(
      h2("Expression along T cell innateness gradient"),
      fluidRow(
        column(width = 6, plotOutput("rnaseq_one_gene")),
        column(width = 6, DT::dataTableOutput("grad_table"))
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
      
      hr(),
      h2("Gene Information"),
      div(id = "geneinfo")
      
    ) # fluidPage
) # tabPanel

panel_data <- tabPanel(
  title = "Data",
  tabsetPanel(
    panel_one_gene
  )
)

ui <- fluidPage(
  useShinyjs(),
  extendShinyjs(script = "www/gene.js", functions = c("queryGene")),
  tags$head(
    tags$link(
      rel = "stylesheet", type = "text/css", href = "app.css"
    ),
    tags$link(rel="shortcut icon", href="favicon.ico"),
    tags$style("#rnaseq_one_gene{max-width:500px;}")
  ),
  # Application title
  navbarPage(
    title = "Innate T Cells",
    panel_data,
    panel_about
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
      head(1e4)
    rownames(grad_table) <- 1:nrow(grad_table)
    grad_table_genes <<- grad_table$Gene
    numeric_cols <- colnames(grad_table)[which_numeric_cols(grad_table)]
    # Javascript-enabled table.
    DT::datatable(
      data = grad_table,
      selection = "single"
    ) %>%
    DT::formatSignif(columns = numeric_cols, digits = 2)
  }, server = FALSE)
  
  output$rnaseq_one_gene <- renderPlot({
    grad_table_rowid <- input$grad_table_rows_selected
    if (length(grad_table_rowid)) {
      this_gene <- grad_table_genes[grad_table_rowid]
    }
    # else if (input$one_gene_symbol %in% all_gene_symbols) {
    #   this_gene <- input$one_gene_symbol
    # }
    # Query mygene.info
    js$queryGene(this_gene)
    if (this_gene %in% gene_symbols) {
      plot_boxplot(this_gene)
    }
  }, width = "auto", height = "auto")
  
  #vis <- reactive({
  #  limma_rowid <- input$grad_table_rows_selected
  #  if (length(limma_rowid)) {
  #    this_gene <- grad_table_genes[limma_rowid]
  #  } else if (input$one_gene_symbol %in% all_gene_symbols) {
  #    this_gene <- input$one_gene_symbol
  #  }
  #  # Query mygene.info
  #  js$queryGene(this_gene)
  #  if (this_gene %in% gene_symbols[rownames(log2tpm)]) {
  #    plot_gene_by_stimulation_ggvis(this_gene, m, log2tpm)
  #  }
  #})
  #vis %>% bind_shiny("rnaseq_one_gene")
}

#

# Launch the app --------------------------------------------------------------

shinyApp(ui = ui, server = server)

#
