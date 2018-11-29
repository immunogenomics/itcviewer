# plot_boxplot <- function(gene, font_size = 1.5) {
#   ensembl_id <- names(which(gene_symbols == gene))
#   m$GENE <- as.numeric(log2tpm[ensembl_id,])
#   gene_stats <- grad[ensembl_id,]
#   par(mar = c(5, 4.6, 3.1, 0.1))
#   boxplot(
#     formula   = GENE ~ cell_type,
#     data      = m,
#     col       = m_colors$cell_type,
#     ylab      = bquote("log"[2]~"(TPM+1)"),
#     #main      = gene,
#     main      = sprintf(
#       "%s\nP = %s, Beta = %s",
#       gene, signif(gene_stats$Pvalue, 2), signif(gene_stats$Beta, 2)
#     ),
#     cex.lab   = font_size,
#     cex.axis  = font_size,
#     cex.main  = font_size,
#     names     = rep("", 7)
#   )
#   corners <- par("usr")
#   y_total <- abs(corners[4] - corners[3])
#   text(
#     x      = seq(1, 7, by = 1),
#     y      = corners[3] - 0.05 * y_total,
#     srt    = 45,
#     adj    = 1,
#     xpd    = TRUE,
#     cex    = 1.5,
#     labels = fancy_celltypes
#   )
#   # legend(
#   #   "topleft",
#   #   legend = c(
#   #     sprintf("P = %s", signif(gene_stats$Pvalue, 2)),
#   #     sprintf("Beta = %s", signif(gene_stats$Beta, 2))
#   #   ),
#   #   bty = "n",
#   #   cex = 1.5
#   # )
# }
# # plot_boxplot("TBX21")
# plot_boxplot("HLA-B")

plot_boxplot <- function(gene, font_size = 1.5) {
  ensembl_id <- names(which(gene_symbols == gene))
  m$GENE <- as.numeric(log2tpm[ensembl_id,])
  gene_stats <- grad[ensembl_id,]
  stat_x <- list(
    x = -Inf, hjust = -0.025
  )
  if (gene_stats$Beta < 0) {
    stat_x <- list(
      x = Inf, hjust = 1.025
    )
  }
  ggplot(m) +
    aes(x = cell_type, y = GENE, fill = cell_type) +
    geom_boxplot() +
    scale_x_discrete(labels = fancy_celltypes) +
    scale_fill_manual(values = m_colors$cell_type, guide = FALSE) +
    theme_bw(base_size = 25) + theme(
      axis.text.x = element_text(color = "black", angle = 33, vjust = 1, hjust = 1),
      axis.text.y = element_text(color = "black"),
      axis.ticks = element_line(size = 0.5),
      title = element_text(face = "italic"),
      legend.position = "bottom",
      panel.grid      = element_blank(),
      panel.border    = element_rect(size = 0.5),
      plot.title      = element_text(size = 30),
      legend.text     = element_text(size = 18)
    ) +
    annotate(
      geom = "text",
      label = sprintf(
        "P = %s, Beta = %s",
        signif(gene_stats$Pvalue, 2),
        signif(gene_stats$Beta, 2)
      ),
      size = 7,
      x = stat_x$x, y = Inf,
      hjust = stat_x$hjust, vjust = 1.25
    ) +
    labs(x = NULL, y = bquote("Log"[2]~"(TPM+1)"), title = gene)
}
# plot_boxplot("HLA-B")
# plot_boxplot("TRAV8-3")
