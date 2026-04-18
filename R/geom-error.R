#' Error bars with automatic orientation
#'
#' A thin wrapper around [ggplot2::geom_errorbar()],
#' [ggplot2::geom_linerange()], [ggplot2::geom_crossbar()], and
#' [ggplot2::geom_pointrange()] that accepts a single `error` aesthetic
#' and figures out orientation from the data.
#'
#' @param mapping Set of aesthetic mappings created by [ggplot2::aes()].
#' @param data The data to be displayed in this layer.
#' @param stat The statistical transformation to use on the data. Defaults
#'   to `"identity"`.
#' @param position Position adjustment.
#' @param ... Other arguments passed on to [ggplot2::layer()].
#' @param err_type One of `"errorbar"` (default), `"linerange"`,
#'   `"crossbar"`, or `"pointrange"`.
#' @param orientation Either `NA` (the default; inferred from the data),
#'   `"x"` (vertical error), or `"y"` (horizontal error).
#' @param na.rm If `FALSE`, missing values are removed with a warning.
#' @param show.legend Logical. Should this layer be included in the legends?
#' @param inherit.aes If `FALSE`, overrides the default aesthetics.
#'
#' @section Aesthetics:
#' `geom_error()` requires `x`, `y`, and `error`. The `error` value is a
#' symmetric half-width applied along the non-categorical axis.
#'
#' @examples
#' library(ggplot2)
#'
#' ggplot(mtcars, aes(mpg, rownames(mtcars))) +
#'   geom_point() +
#'   geom_error(aes(error = drat))
#'
#' ggplot(mtcars, aes(factor(cyl), mpg)) +
#'   geom_point() +
#'   geom_error(aes(error = drat), err_type = "pointrange")
#'
#' @export
geom_error <- function(mapping = NULL, data = NULL,
                       stat = "identity", position = "identity",
                       ...,
                       err_type = "errorbar",
                       orientation = NA,
                       na.rm = FALSE,
                       show.legend = NA,
                       inherit.aes = TRUE) {
  ggplot2::layer(
    geom        = GeomError,
    mapping     = mapping,
    data        = data,
    stat        = stat,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = list(
      err_type    = err_type,
      orientation = orientation,
      na.rm       = na.rm,
      ...
    )
  )
}

#' @rdname geom_error
#' @export
geom_err <- geom_error

#' @rdname geom_error
#' @export
geom_error_linerange <- function(..., err_type) {
  if (!missing(err_type)) {
    cli::cli_abort(
      "{.fn geom_error_linerange} pins {.arg err_type} to {.val linerange}; \\
       do not pass it."
    )
  }
  geom_error(..., err_type = "linerange")
}

#' @rdname geom_error
#' @export
geom_error_crossbar <- function(..., err_type) {
  if (!missing(err_type)) {
    cli::cli_abort(
      "{.fn geom_error_crossbar} pins {.arg err_type} to {.val crossbar}; \\
       do not pass it."
    )
  }
  geom_error(..., err_type = "crossbar")
}

#' @rdname geom_error
#' @export
geom_error_pointrange <- function(..., err_type) {
  if (!missing(err_type)) {
    cli::cli_abort(
      "{.fn geom_error_pointrange} pins {.arg err_type} to {.val pointrange}; \\
       do not pass it."
    )
  }
  geom_error(..., err_type = "pointrange")
}

#' @rdname geom_error
#' @format NULL
#' @usage NULL
#' @export
GeomError <- ggplot2::ggproto(
  "GeomError", ggplot2::Geom,

  required_aes = c("x", "y", "error"),

  default_aes = ggplot2::aes(
    colour    = "black",
    fill      = NA,
    linewidth = 0.5,
    linetype  = 1,
    shape     = 19,
    size      = 1.5,
    alpha     = NA,
    width     = 0.5
  ),

  draw_key = ggplot2::draw_key_path,

  extra_params = c("na.rm", "err_type", "orientation"),

  setup_params = function(data, params) {
    valid <- c("errorbar", "linerange", "crossbar", "pointrange")
    err_type <- params$err_type %||% "errorbar"
    if (!err_type %in% valid) {
      cli::cli_abort(
        "{.arg err_type} must be one of {.val {valid}}, not {.val {err_type}}."
      )
    }
    params$err_type    <- err_type
    params$orientation <- infer_orientation(data, params)
    params$flipped_aes <- params$orientation == "y"
    params
  },

  setup_data = function(data, params) {
    data$flipped_aes <- params$flipped_aes
    data <- ggplot2::flip_data(data, params$flipped_aes)

    # Error range along canonical y-axis
    data$ymin <- data$y - data$error
    data$ymax <- data$y + data$error
    data$error <- NULL

    # Cap/box horizontal bounds from width
    width <- data$width %||% params$width %||%
      (ggplot2::resolution(data$x, FALSE) * 0.9)
    data$width <- NULL
    data$xmin <- data$x - width / 2
    data$xmax <- data$x + width / 2

    ggplot2::flip_data(data, params$flipped_aes)
  },

  draw_panel = function(self, data, panel_params, coord,
                        err_type    = "errorbar",
                        orientation = "y",
                        flipped_aes = TRUE,
                        lineend     = "butt",
                        linejoin    = "mitre",
                        na.rm       = FALSE,
                        ...) {
    geom <- switch(
      err_type,
      errorbar   = ggplot2::GeomErrorbar,
      linerange  = ggplot2::GeomLinerange,
      crossbar   = ggplot2::GeomCrossbar,
      pointrange = ggplot2::GeomPointrange,
      cli::cli_abort("Invalid {.arg err_type}: {.val {err_type}}.")
    )

    args <- list(
      data         = data,
      panel_params = panel_params,
      coord        = coord,
      flipped_aes  = flipped_aes
    )
    if (err_type %in% c("errorbar", "linerange", "crossbar")) {
      args$lineend <- lineend
    }
    if (err_type == "crossbar") {
      args$linejoin <- linejoin
    }

    do.call(geom$draw_panel, args)
  }
)
