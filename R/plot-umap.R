#' Get the quantile breaks in a numeric vector.
#' @param x A numeric vector.
#' @param n The number of breaks.
#' @return A vector with unique breaks.
quantile_breaks <- function(x, n = 10) {
  breaks <- quantile(x, probs = seq(0, 1, length.out = n))
  breaks[!duplicated(breaks)]
}

#' Create 2 scatter plots side by side.
#' The left plot is colored by marker.
#' The right plot is colored by cluster.
#' @param dat A dataframe with columns umap1, umap2, marker, cluster
plot_umap <- function(dat, umap_x = "umap1", umap_y = "umap2", title = NULL) {
  n_nonzero  <- sum(dat$marker > 0)
  # umap_title <- bquote("umap of PCA on Log"[2]~"(CPM + 1)")
  point_size <- 2.0
  if (nrow(dat) < 5000) {
    point_size <- 2.5
  }
  fill_values <- quantile_breaks(dat$marker, n = 9)
  fill_values <- fill_values / max(fill_values)
  fill_palette <- RColorBrewer::brewer.pal(9, "Greens")
  theme_umap_1 <- theme_bw(base_size = 25) + theme(
    legend.position = "bottom",
    axis.text       = element_blank(),
    axis.ticks      = element_blank(),
    panel.grid      = element_blank(),
    panel.border    = element_rect(size = 0.5),
    plot.title      = element_text(size = 30),
    legend.text     = element_text(size = 18),
    # Top, Right, Bottom, Left
    legend.margin   = margin(0, 0, 0, 0),
    legend.box.margin   = margin(-10, -10, 0, -10)
  )
  theme_umap_2 <- theme_bw(base_size = 25) + theme(
    legend.position = "bottom",
    axis.text       = element_blank(),
    axis.ticks      = element_blank(),
    panel.grid      = element_blank(),
    panel.border    = element_rect(size = 0.5),
    plot.title      = element_text(size = 30),
    legend.text     = element_text(size = 18),
    # Top, Right, Bottom, Left
    legend.margin   = margin(0, 0, 0, 0),
    legend.box.margin   = margin(-10, -10, 0, -10)
  )
  p1 <- ggplot() +
    geom_point(
      data    = subset(dat, marker <= 0),
      mapping = aes_string(x = umap_x, y = umap_y),
      size    = point_size,
      shape   = 19,
      color   = "grey95"
    ) +
    geom_point(
      data    = subset(dat[order(dat$marker),], marker > 0),
      mapping = aes_string(x = umap_x, y = umap_y, fill = "marker"),
      size    = point_size,
      shape   = 21,
      stroke  = 0.15
    ) +
    # scale_fill_gradientn(
    #   # Linear scale
    #   # colours = fill_palette,
    #   # Quantile scale
    #   colours = colorRampPalette(fill_palette)(length(fill_values)),
    #   values  = fill_values,
    #   breaks  = scales::pretty_breaks(n = 4),
    #   name    = bquote("Log"[2]~"(CPM+1)  ")
    # ) +
    scale_fill_gradientn(
      # Linear scale
      # colours = fill_palette,
      # Quantile scale
      colours = colorRampPalette(fill_palette)(9),
      # values  = fill_values,
      breaks  = scales::pretty_breaks(n = 4),
      name    = bquote("Log"[2]~"(CPM+1)  ")
    ) +
    guides(
      fill  = guide_colorbar(
        ticks.linewidth = 1,
        ticks.colour = "black",
        frame.colour = "black",
        title.position = "left",
        barwidth = 10, barheight = 1
      ),
      alpha = "none"
    ) +
    labs(x = NULL, y = NULL, title = substitute(italic(x), list(x = title))) +
    theme_umap_1
  
  # Make a plot showing the clustering results.
  dat$cluster <- factor(dat$cluster)
  p2 <- ggplot() +
    geom_point(
      data    = dat[sample(nrow(dat)),],
      # mapping = aes(x = T1, y = T2, fill = cluster),
      mapping = aes_string(x = umap_x, y = umap_y, fill = "cluster"),
      size    = point_size,
      shape   = 21,
      stroke  = 0.12
    ) +
    # scale_fill_brewer(type = "qual", palette = "Set3", name = "Cluster") +
    scale_fill_manual(
      name = "Cell Type",
      labels = fancy_celltypes,
      values = m_colors$cell_type
    ) +
    guides(
      fill = guide_legend(title = NULL, nrow = 2, override.aes = list(size = 6))
    ) +
    labs(x = NULL, y = NULL, title = "Cell Types") +
    theme_umap_2
  
  bottom_text <- sprintf(
    "%s cells: %s (%s%%) non-zero",
    comma(nrow(dat)),
    comma(n_nonzero),
    signif(100 * n_nonzero / nrow(dat), 2)
  )
  
  p1 + p2 + plot_annotation(
    caption = bottom_text,
    theme = theme(
      plot.caption = element_text(size = 18, hjust = 0.5)
    )
  )
}
# bad_gene <- "TRBV6-5"
# bad_gene %in% rownames(s$log2cpm)
# s$meta$marker <- as.numeric(s$log2cpm[bad_gene,])
plot_umap(s$meta)
# 
