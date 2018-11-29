save_figure <- function(
  filename = NULL, width = 6, height = 5, dpi = 100,
  html_style = "height: 100%; width: 100%; object-fit: contain",
  html_alt = NULL,
  ggplot_function = NULL
) {
  out_dir <- "www/figures"
  dir.create(out_dir, showWarnings = FALSE)
  filename <- file.path(out_dir, filename)
  # Set to FALSE to disable caching figures.
  cache <- TRUE
  if (!cache || !file.exists(filename) || file_test("-nt", "app.R", filename)) {
    if (is.null(ggplot_function)) {
      stop("ggplot_function is NULL")
    }
    p <- ggplot_function()
    ggsave(
      filename = filename, plot = p,
      width = width, height = height, dpi = dpi
    )
    optimize_png(filename)
  }
  filename_hash <- digest::digest(file = filename, algo = "sha1")
  glue(
    '<img style="{style}" src="{src}" alt="{alt}"></img>',
    style = html_style,
    src = glue(
      "{png}?sha1={hash}",
      png = str_remove(filename, "www/"), hash = filename_hash
    ),
    alt = html_alt
  )
}
