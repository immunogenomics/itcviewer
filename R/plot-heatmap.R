plot_heatmap <- function(gene, n = 20, font_size = 1.5) {
  this_gene <- gene
  ensembl_id <- names(which(gene_symbols == gene))
  cors <- as.numeric(cor(x = t(log2tpm[ensembl_id,]), y = t(log2tpm)))
  names(cors) <- rownames(log2tpm)
  cors <- head(cors[order(abs(cors), decreasing = TRUE)], n + 1)
  
  d <- data.frame(
    m[,c("sampleID", "cell_type")],
    scale(t(log2tpm[names(cors),]))
  )
  o <- seriate(x = as.matrix(d[,3:ncol(d)]), method = "PCA")
  
  d <- d %>% gather(gene, value, -sampleID, -cell_type)
  
  d$gene     <- factor(d$gene, names(cors)[o[[2]]])
  d$sampleID <- factor(d$sampleID, colnames(log2tpm)[o[[1]]])
  
  label_fancy <- as_labeller(function(xs) {
    sapply(xs, function(x) parse(
      text = fancy_celltypes[x]
    ))
  }, default = label_parsed)
  
  ggplot(d) +
    geom_tile(aes(x = sampleID, y = gene, fill = value)) +
    facet_grid(
      ~ cell_type, scales = "free_x",
      labeller = label_fancy
    ) +
    scale_fill_distiller(
      type = "div", palette = "RdBu", limits = c(-1, 1) * max(abs(d$value))
    ) +
    scale_x_discrete(expand = c(0, 0)) +
    scale_y_discrete(
      expand = c(0, 0),
      labels = function(x) {
        retval <- gene_symbols[x]
        retval[retval == this_gene] <- paste("*", this_gene)
        retval
      }
    ) +
    guides(
      fill = guide_colorbar(
        frame.colour = "black",
        title = "Scaled Expression",
        barwidth = 20,
        ticks.colour = "white",
        ticks.linewidth = 1.5
      )
    ) +
    theme_void() +
    theme(plot.title = element_text(size = 18, margin = margin(b = 7)),
      plot.margin = margin(l = 5, t = 5, b = 5, r = 5),
      panel.border = element_rect(fill = NA, size = 0.3),
      legend.title = element_text(size = 18),
      legend.text = element_text(size = 18),
      legend.position = "bottom",
      strip.text = element_text(
        size = 18, margin = margin(b = 5)
      ),
      axis.text.y = element_text(
        size = 18, face = "italic", margin = margin(r = 5)
      )
    ) +
    labs(title = glue("{n} genes correlated with {a}", n = n, a = this_gene))
}
plot_heatmap("HLA-B")
# plot_heatmap("TRAV8-3")

