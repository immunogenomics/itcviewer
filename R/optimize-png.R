#' Test if a program is installed.
is_installed <- function(command) {
  !startsWith(system(
    command = sprintf("command -v %s || echo FALSE", command),
    intern = TRUE
  ), "FALSE")
}

#' Call pngquant to optimize a PNG file.
optimize_png <- function(filename) {
  if (is_installed("pngquant")) {
    opt_filename <- sprintf(
      "%s-fs8.png", substr(filename, 1, nchar(filename) - 4)
    )
    command <- sprintf(
      "pngquant --speed=2 --ext -fs8.png -- %s && mv -f %s %s",
      filename, opt_filename, filename
    )
    system(command)
  }
}