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
#' @param error_geom One of `"errorbar"` (default), `"linerange"`,
#'   `"crossbar"`, or `"pointrange"`. Chooses which ggplot2 range geom
#'   `geom_error()` dispatches to under the hood.
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
#'   geom_error(aes(error = drat), error_geom = "pointrange")
#'
#' @export
geom_error <- function(mapping = NULL, data = NULL,
                       stat = "identity", position = "identity",
                       ...,
                       error_geom = "errorbar",
                       orientation = NA,
                       na.rm = FALSE,
                       show.legend = NA,
                       inherit.aes = TRUE) {
  call <- rlang::caller_env()
  check_error_geom(error_geom, call = call)
  check_orientation(orientation, call = call)

  ggplot2::layer(
    geom        = GeomError,
    mapping     = mapping,
    data        = data,
    stat        = stat,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = list(
      error_geom  = error_geom,
      orientation = orientation,
      na.rm       = na.rm,
      ...
    )
  )
}

 
#' @rdname geom_error
#' @export
geom_error_linerange <- function(..., error_geom) {
  check_pinned_error_geom(
    missing(error_geom),
    fn = "geom_error_linerange",
    type = "linerange",
    call = rlang::caller_env()
  )
  geom_error(..., error_geom = "linerange")
}

#' @rdname geom_error
#' @export
geom_error_crossbar <- function(..., error_geom) {
  check_pinned_error_geom(
    missing(error_geom),
    fn = "geom_error_crossbar",
    type = "crossbar",
    call = rlang::caller_env()
  )
  geom_error(..., error_geom = "crossbar")
}

#' @rdname geom_error
#' @export
geom_error_pointrange <- function(..., error_geom) {
  check_pinned_error_geom(
    missing(error_geom),
    fn = "geom_error_pointrange",
    type = "pointrange",
    call = rlang::caller_env()
  )
  geom_error(..., error_geom = "pointrange")
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
    size      = 0.5,
    stroke    = 1,
    alpha     = NA,
    width     = 0.5
  ),

  draw_key = ggplot2::draw_key_path,

  extra_params = c("na.rm", "error_geom", "orientation"),

  setup_params = function(data, params) {
    params$error_geom  <- params$error_geom %||% "errorbar"
    params$orientation <- infer_orientation(data, params)
    params$flipped_aes <- params$orientation == "y"
    params
  },

  setup_data = function(data, params) {
    check_error_aes(data$error)

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
                        error_geom  = "errorbar",
                        orientation = "y",
                        flipped_aes = TRUE,
                        lineend     = "butt",
                        linejoin    = "mitre",
                        fatten      = NULL,
                        na.rm       = FALSE) {
    base <- list(
      data         = data,
      panel_params = panel_params,
      coord        = coord,
      flipped_aes  = flipped_aes,
      lineend      = lineend
    )

    grob <- switch(
      error_geom,
      errorbar = do.call(
        ggplot2::GeomErrorbar$draw_panel,
        base
      ),
      linerange = do.call(
        ggplot2::GeomLinerange$draw_panel,
        c(base, list(na.rm = na.rm))
      ),
      crossbar = do.call(
        ggplot2::GeomCrossbar$draw_panel,
        c(base, list(linejoin = linejoin, fatten = fatten %||% 2.5))
      ),
      pointrange = do.call(
        ggplot2::GeomPointrange$draw_panel,
        c(base, list(fatten = fatten %||% 4, na.rm = na.rm))
      )
    )
    grob
  }
)
