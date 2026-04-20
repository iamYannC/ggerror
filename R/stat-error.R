#' Summarising stat for `geom_error()`
#'
#' `stat_error()` computes the error bounds from raw observation-level data
#' using ggplot2's `fun.data` contract. Where [geom_error()] expects pre-
#' computed error columns, `stat_error()` summarises `y` (or `x`, when
#' orientation is horizontal) within each group via the function supplied to
#' `fun`.
#'
#' @param mapping,data,position,show.legend,inherit.aes Standard ggplot2
#'   layer arguments.
#' @param geom The geom to render the summary with. Defaults to
#'   [GeomErrorStat], which reuses `geom_error()`'s draw path.
#' @param fun One of `"mean_se"` (default, uses [ggplot2::mean_se()]),
#'   `"mean_ci"` (mean with 95% normal-theory CI via [stats::qt()]; no
#'   Hmisc dependency), or a function taking a numeric vector and returning
#'   a single-row data.frame with columns `y`, `ymin`, `ymax`.
#' @param error_geom One of `"errorbar"` (default), `"linerange"`,
#'   `"crossbar"`, `"pointrange"`.
#' @param orientation `NA` (default, inferred), `"x"`, or `"y"`.
#' @param na.rm If `TRUE`, drop `NA` values from the summarised axis before
#'   applying `fun`.
#' @param ... Additional parameters passed through to [geom_error()], e.g.
#'   per-side styling (`colour_neg`, `width_pos`, …).
#'
#' @examples
#' library(ggplot2)
#'
#' ggplot(mtcars, aes(factor(cyl), mpg)) + stat_error()
#'
#' ggplot(mtcars, aes(factor(cyl), mpg)) +
#'   stat_error(fun = "mean_ci", error_geom = "pointrange")
#'
#' @export
stat_error <- function(mapping = NULL, data = NULL,
                       geom = NULL, position = "identity",
                       ...,
                       fun = "mean_se",
                       error_geom = "errorbar",
                       orientation = NA,
                       na.rm = FALSE,
                       show.legend = NA,
                       inherit.aes = TRUE) {
  call <- rlang::caller_env()
  params <- list(...)
  check_error_geom(error_geom, call = call)
  check_orientation(orientation, call = call)
  check_per_side_params(params, call = call)

  ggplot2::layer(
    stat        = StatError,
    geom        = geom %||% GeomErrorStat,
    mapping     = mapping,
    data        = data,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = c(list(
      fun         = fun,
      error_geom  = error_geom,
      orientation = orientation,
      na.rm       = na.rm
    ), params)
  )
}

#' @rdname stat_error
#' @format NULL
#' @usage NULL
#' @export
StatError <- ggplot2::ggproto(
  "StatError", ggplot2::Stat,

  required_aes = c("x", "y"),

  extra_params = c("na.rm", "fun", "orientation"),

  setup_params = function(data, params) {
    params$fun         <- params$fun %||% "mean_se"
    params$orientation <- infer_orientation(data, params)
    params$flipped_aes <- params$orientation == "y"
    params
  },

  compute_group = function(data, scales,
                           fun = "mean_se",
                           orientation = NA,
                           flipped_aes = FALSE,
                           na.rm = FALSE,
                           ...) {
    fn   <- resolve_stat_fun(fun)
    data <- ggplot2::flip_data(data, flipped_aes)
    y    <- if (isTRUE(na.rm)) data$y[!is.na(data$y)] else data$y
    res  <- validate_stat_fun_return(fn(y))

    out <- data.frame(
      x           = data$x[1],
      y           = res$y,
      error_neg   = res$y - res$ymin,
      error_pos   = res$ymax - res$y,
      flipped_aes = flipped_aes
    )
    ggplot2::flip_data(out, flipped_aes)
  }
)

#' @rdname stat_error
#' @format NULL
#' @usage NULL
#' @export
GeomErrorStat <- ggplot2::ggproto(
  "GeomErrorStat", GeomError,
  required_aes = c("x", "y"),

  setup_params = function(data, params) {
    params$error_geom <- params$error_geom %||% "errorbar"
    if (!is.null(data$flipped_aes)) {
      params$flipped_aes <- isTRUE(data$flipped_aes[1])
      params$orientation <- if (params$flipped_aes) "y" else "x"
    } else {
      params$orientation <- infer_orientation(data, params)
      params$flipped_aes <- params$orientation == "y"
    }
    params
  }
)

#' @keywords internal
#' @noRd
resolve_stat_fun <- function(fun, call = rlang::caller_env()) {
  if (is.function(fun)) {
    return(fun)
  }
  if (!is.character(fun) || length(fun) != 1L) {
    cli::cli_abort(
      "{.arg fun} must be {.val mean_se}, {.val mean_ci}, or a function.",
      class = "ggerror_error_bad_fun",
      call  = call
    )
  }
  switch(
    fun,
    mean_se = ggplot2::mean_se,
    mean_ci = mean_cl_normal_internal,
    cli::cli_abort(
      "{.arg fun} must be {.val mean_se}, {.val mean_ci}, or a function, \\
       not {.val {fun}}.",
      class = "ggerror_error_bad_fun",
      call  = call
    )
  )
}

#' @keywords internal
#' @noRd
mean_cl_normal_internal <- function(y, conf.int = 0.95, na.rm = TRUE) {
  if (isTRUE(na.rm)) y <- y[!is.na(y)]
  n  <- length(y)
  m  <- mean(y)
  se <- stats::sd(y) / sqrt(n)
  tq <- stats::qt((1 + conf.int) / 2, df = n - 1)
  data.frame(y = m, ymin = m - tq * se, ymax = m + tq * se)
}

#' @keywords internal
#' @noRd
validate_stat_fun_return <- function(res, call = rlang::caller_env()) {
  ok <- is.data.frame(res) &&
    nrow(res) == 1L &&
    all(c("y", "ymin", "ymax") %in% names(res))
  if (!ok) {
    got <- if (is.data.frame(res)) {
      paste(nrow(res), "rows")
    } else {
      paste(length(res), "elements")
    }
    cli::cli_abort(
      c(
        "{.arg fun} must return a single-row data.frame with columns \\
         {.val y}, {.val ymin}, {.val ymax}.",
        i = "Got: {.cls {class(res)[1]}} with {got}."
      ),
      class = "ggerror_error_bad_fun_return",
      call  = call
    )
  }
  if (!is.numeric(res$y) || !is.numeric(res$ymin) || !is.numeric(res$ymax)) {
    cli::cli_abort(
      "{.arg fun} must return numeric {.val y}, {.val ymin}, {.val ymax}.",
      class = "ggerror_error_bad_fun_return",
      call  = call
    )
  }
  if (res$ymin > res$y || res$ymax < res$y) {
    cli::cli_abort(
      "{.arg fun} must return {.code ymin <= y <= ymax}.",
      class = "ggerror_error_bad_fun_return",
      call  = call
    )
  }
  res
}
