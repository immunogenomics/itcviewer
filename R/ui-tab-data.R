tabPanel(
  title = "Home",
  value = "data",
  
  fluidPage(
    HTML("
<h1 class='display-4 font-weight-normal'>Innate T cells</h1>
<p class='lead font-weight-normal'>Explore gene expression along the T cell innateness gradient.</p>
    "),
    hr(),
    fluidRow(
      # column(width = 6, plotOutput("rnaseq_one_gene")),
      column(
        width = 6,
        h3("Low input RNA-seq with sorted T cell populations"),
        htmlOutput("rnaseq_one_gene", style = "min-height: 350px;")
      ),
      column(
        width = 6,
        h3("Association with innateness gradient"),
        DT::dataTableOutput("grad_table"),
        style = "min-height: 674.4px;"
      )
    ),
    fluidRow(
      # column(width = 12, plotOutput("scrnaseq_umap"))
      column(
        width = 12,
        h3("Single-cell RNA-seq expression and cell clusters"),
        htmlOutput("scrnaseq_umap", style = "width: 100%; height: 0; padding-top: 60%; position: relative;")
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
    
    fluidRow(
      column(
        width = 12,
        h3("Correlated genes in low input RNA-seq data"),
        # Put the selected gene first.
        htmlOutput("rnaseq_heatmap", style = "width: 100%; height: 0; padding-top: 66.66%; position: relative;")
      )
    ),
    
    hr(),
    HTML(
      "
      <h2>Read the paper</h2>
      <div class='mypaper'>
      <h3>
      <b>A genome-wide innateness gradient defines the functional state of human innate T cells.</b>
      </h3>
      <p>Maria Gutierrez-Arcelus, Nikola Teslovich, Alex R Mola, Hyun Kim, Susan Hannes,
      Kamil Slowikowski, Gerald F. M. Watts, Michael Brenner, Soumya Raychaudhuri,
      Patrick J. Brennan.
      </p>
      <p><i>bioRxiv</i> 2018.
      <a href='https://doi.org/10.1101/280370'>https://doi.org/10.1101/280370</a>
      </p>
      </div>"
    ),
    h2("Contact us"),
    p(
      "Please ",
      a("contact Dr. Maria Gutierrez-Arcelus", href = "mailto:mgutierr@broadinstitute.org"),
      " with any questions, requests, or comments."
    ),
    HTML(
      "
      <h2>Get the data</h2>
      <p>The data presented here comes from the laboratories of:
      <ul>
      <li><a href='https://connects.catalyst.harvard.edu/Profiles/display/Person/56904'>Dr. Patrick J. Brennan</a></li>
      <li><a href='https://immunogenomics.hms.harvard.edu/'>Dr. Soumya Raychaudhuri</a></li>
      <li><a href='https://www.hms.harvard.edu/dms/immunology/fac/Brenner.php'>Dr. Michael B. Brenner</a></li>
      </ul>
      </p>
      <p>Download the data from NCBI GEO:
      <ul><li><a href='https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE124731'>GSE124731</a></li></ul>
      </p>"
    ),
    HTML(
      "
      <h2>Get the code</h2>
      <p>Get the code for the analysis:
<ul><li><a href='https://github.com/immunogenomics/itc'>github.com/immunogenomics/itc</a></li></ul>
      </p>
      <p>Get the code for this website:
<ul><li><a href='https://github.com/immunogenomics/itcviewer'>github.com/immunogenomics/itcviewer</a></li></ul>
      </p>
      "
    ),
    h3("Disclaimer"),
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
)