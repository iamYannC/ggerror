#' Infer plot orientation for geom_error()
#'
#' Looks at the raw `x` and `y` columns of the layer data. If one is
#' discrete (character/factor) and the other numeric, orientation is
#' chosen so that the error aesthetic expands along the numeric axis.
#' When both axes are numeric, orientation defaults to `"y"` and an
#' informative message is emitted.
#'
#' @param data A data frame with at least `x` and `y` columns.
#' @param params A named list of layer parameters. If `params$orientation`
#'   is `"x"` or `"y"`, it is returned verbatim.
#'
#' @return Either `"x"` or `"y"`.
#' @keywords internal
#' @noRd
infer_orientation <- function(data, params = list()) {
  explicit <- params$orientation
  if (!is.null(explicit) && !is.na(explicit)) {
    return(explicit)
  }

  x_discrete <- is_discrete_axis(data$x)
  y_discrete <- is_discrete_axis(data$y)

  if (y_discrete && !x_discrete) return("y")
  if (x_discrete && !y_discrete) return("x")

  cli::cli_inform(c(
    i = "Both axes appear numeric; defaulting {.arg orientation} to {.val y}.",
    "*" = "Pass {.code orientation = \"x\"} for vertical error bars."
  ))
  "y"
}

#' @keywords internal
#' @noRd
is_discrete_axis <- function(x) {
  is.character(x) || is.factor(x) || inherits(x, "mapped_discrete")
}
