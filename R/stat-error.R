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
#' @param conf.int Confidence level forwarded to `fun` when the function
#'   accepts a `conf.int` argument (e.g. `fun = "mean_ci"` or a custom
#'   `fun.data` with that formal). Ignored for funs that don't declare it,
#'   so it's safe to leave at the default when using `fun = "mean_se"`.
#' @param fun.args Named list of extra arguments to pass to `fun`. Merged
#'   with any `...` arguments whose names match `fun`'s formals; `fun.args`
#'   wins on collision.
#' @param ... Additional parameters. Names that match `fun`'s formals (or
#'   any name, when `fun` accepts `...`) are forwarded to `fun`; the
#'   remainder go to [geom_error()] as per-side styling (`colour_neg`,
#'   `width_pos`, …) or standard aesthetics.
#'
#' @examples
#' library(ggplot2)
#'
#' ggplot(mtcars, aes(factor(cyl), mpg)) + stat_error()
#'
#' ggplot(mtcars, aes(factor(cyl), mpg)) +
#'   stat_error(fun = "mean_ci", error_geom = "pointrange")
#'
#' # 90% CI with NA-tolerant summarising:
#' ggplot(mtcars, aes(factor(cyl), mpg)) +
#'   stat_error(fun = "mean_ci", conf.int = 0.9, na.rm = TRUE)
#'
#' @export
stat_error <- function(mapping = NULL, data = NULL,
                       geom = NULL, position = "identity",
                       ...,
                       fun = "mean_se",
                       fun.args = list(),
                       error_geom = "errorbar",
                       orientation = NA,
                       na.rm = FALSE,
                       conf.int = 0.95,
                       show.legend = NA,
                       inherit.aes = TRUE) {
  call <- rlang::caller_env()
  dots <- list(...)

  fun_missing      <- missing(fun)
  conf_int_missing <- missing(conf.int)

  check_error_geom(error_geom, call = call)
  check_orientation(orientation, call = call)
  check_conf_int(conf.int, call = call)

  inform_stat_defaults(fun, fun_missing, conf.int, conf_int_missing)
  warn_conf_int_ignored(fun, conf_int_missing)

  fn           <- resolve_stat_fun(fun, call = call)
  split        <- split_dots_for_fun(dots, fn)
  auto_fun     <- split$to_fun
  geom_params  <- split$to_geom

  fun.args <- utils::modifyList(auto_fun, as.list(fun.args))

  check_per_side_params(geom_params, call = call)

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
      fun.args    = fun.args,
      error_geom  = error_geom,
      orientation = orientation,
      na.rm       = na.rm,
      conf.int    = conf.int
    ), geom_params)
  )
}

#' @rdname stat_error
#' @format NULL
#' @usage NULL
#' @export
StatError <- ggplot2::ggproto(
  "StatError", ggplot2::Stat,

  required_aes = c("x", "y"),

  extra_params = c("na.rm", "fun", "fun.args", "conf.int", "orientation"),

  setup_params = function(data, params) {
    params$fun         <- params$fun %||% "mean_se"
    params$fun.args    <- params$fun.args %||% list()
    params$conf.int    <- params$conf.int %||% 0.95
    params$orientation <- infer_orientation(data, params)
    params$flipped_aes <- params$orientation == "y"
    params
  },

  setup_data = function(data, params) {
    check_summary_group_sizes(data, params$flipped_aes)
    data
  },

  compute_group = function(data, scales,
                           fun = "mean_se",
                           fun.args = list(),
                           orientation = NA,
                           flipped_aes = FALSE,
                           na.rm = FALSE,
                           conf.int = 0.95,
                           ...) {
    fn   <- resolve_stat_fun(fun)
    data <- ggplot2::flip_data(data, flipped_aes)
    y    <- if (isTRUE(na.rm)) data$y[!is.na(data$y)] else data$y
    res  <- validate_stat_fun_return(call_stat_fun(fn, y, conf.int, fun.args))

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
call_stat_fun <- function(fn, y, conf.int, fun.args = list()) {
  fmls     <- names(formals(fn))
  has_dots <- "..." %in% fmls
  args     <- list(y)
  if (has_dots || "conf.int" %in% fmls) {
    args$conf.int <- conf.int
  }
  if (length(fun.args)) {
    matched <- if (has_dots) fun.args else fun.args[names(fun.args) %in% fmls]
    for (nm in names(matched)) args[[nm]] <- matched[[nm]]
  }
  do.call(fn, args)
}

# Split `...` into args destined for `fun` vs. args destined for the geom.
# Names matching `fn`'s explicit formals go to `fun`. If `fn` accepts `...`,
# names that aren't known geom/aesthetic params also go to `fun`.
#' @keywords internal
#' @noRd
split_dots_for_fun <- function(dots, fn) {
  if (!length(dots)) {
    return(list(to_fun = list(), to_geom = list()))
  }
  nms <- names(dots) %||% rep("", length(dots))
  if (any(!nzchar(nms))) {
    return(list(to_fun = list(), to_geom = dots))
  }
  fmls        <- names(formals(fn))
  fn_has_dots <- "..." %in% fmls
  fn_fmls     <- setdiff(fmls, c("...", "y", "x", "data"))

  geom_names <- c(
    per_side_param_names,
    "colour", "color", "fill", "linewidth", "linetype", "alpha",
    "width", "size", "shape", "stroke", "group"
  )
  reserved <- c("na.rm", "conf.int", "orientation", "error_geom", "fun",
                "fun.args", "flipped_aes")

  to_fun_mask <- nms %in% fn_fmls
  if (fn_has_dots) {
    to_fun_mask <- to_fun_mask |
      (!nms %in% geom_names & !nms %in% reserved)
  }
  list(to_fun = dots[to_fun_mask], to_geom = dots[!to_fun_mask])
}

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

#' @keywords internal
#' @noRd
inform_stat_defaults <- function(fun, fun_missing, conf.int, conf_int_missing) {
  show_fun <- fun_missing && is.character(fun) && length(fun) == 1L
  show_ci  <- conf_int_missing && identical(fun, "mean_ci")
  if (!show_fun && !show_ci) return(invisible())

  pieces <- character()
  # If we mention conf.int, mention the fun it pairs with too, even when the
  # user passed `fun` explicitly — reader shouldn't have to infer context.
  if (show_fun || show_ci) {
    pieces <- c(pieces, sprintf("fun = \"%s\"", fun))
  }
  if (show_ci) {
    pieces <- c(pieces, sprintf("conf.int = %s", format(conf.int)))
  }
  cli::cli_inform(
    "{.fn stat_error} using {paste(pieces, collapse = ' and ')}.",
    class = "ggerror_message_defaults"
  )
}

# Flag explicit `conf.int` with a fun that can't use it. `mean_se` is the
# common offender — users reach for `conf.int = 0.95` expecting a CI and
# silently get ±1 SE instead. Warning (not error) so old scripts still run.
#' @keywords internal
#' @noRd
warn_conf_int_ignored <- function(fun, conf_int_missing) {
  if (conf_int_missing) return(invisible())
  if (!identical(fun, "mean_se")) return(invisible())
  cli::cli_warn(
    c(
      "{.arg conf.int} has no effect when {.code fun = \"mean_se\"}.",
      i = "For a normal-theory CI, use {.code fun = \"mean_ci\"}.",
      i = "To silence this warning, drop {.arg conf.int} or switch {.arg fun}."
    ),
    class = "ggerror_warn_conf_int_ignored"
  )
}

# Summary stats need at least two observations per group; with n = 1 the SE
# is undefined and both built-in funs silently return NA bounds. Raised in
# setup_data (before ggplot2's compute_panel try_fetch) so users get a hard
# error instead of a warning-with-blank-panel.
#' @keywords internal
#' @noRd
check_summary_group_sizes <- function(data, flipped_aes,
                                      call = rlang::caller_env()) {
  summary_col <- if (isTRUE(flipped_aes)) "x" else "y"
  group_col   <- if (isTRUE(flipped_aes)) "y" else "x"
  if (is.null(data[[summary_col]]) || is.null(data$group)) {
    return(invisible())
  }
  counts <- vapply(
    split(data[[summary_col]], data$group),
    function(v) sum(!is.na(v)),
    integer(1)
  )
  bad <- counts[counts < 2L]
  if (!length(bad)) return(invisible())

  bad_groups <- names(bad)
  group_vals <- data[[group_col]][match(as.integer(bad_groups), data$group)]
  shown      <- utils::head(group_vals, 5)
  more       <- length(bad_groups) - length(shown)
  suffix     <- if (more > 0) sprintf(" (+ %d more)", more) else ""
  cli::cli_abort(
    c(
      "{.fn stat_error} needs at least 2 observations per group, \\
       but {length(bad)} group{?s} {?has/have} fewer.",
      i = "{cli::qty(length(shown))} Offending {group_col} value{?s}: \\
           {.val {shown}}{suffix}.",
      i = "Check that your mapping groups multiple rows per level, \\
           or pre-compute the bounds and use {.fn geom_error} instead."
    ),
    class = "ggerror_error_too_few_obs",
    call  = call
  )
}
