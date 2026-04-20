#' Error bars with automatic orientation
#'
#' A thin wrapper around [ggplot2::geom_errorbar()],
#' [ggplot2::geom_linerange()], [ggplot2::geom_crossbar()], and
#' [ggplot2::geom_pointrange()] that accepts a single `error` aesthetic
#' and figures out orientation from the data. For asymmetric errors, use
#' `error_neg` + `error_pos` instead of `error`.
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
#' @section Niche parameters (via `...`):
#' - `zero_threshold` — numeric tolerance (default `1e-8`) for the
#'   uniformly-zero check that drives the `0 -> NA` deprecation.
#' - `silent_zero_warning` — `TRUE` suppresses that deprecation.
#'
#' @param sign_aware If `TRUE`, signed values in `error` are routed per
#'   row: positive values extend the bar in the positive direction,
#'   negative values extend it in the negative direction, and the
#'   opposite side is suppressed. Useful for residual plots where
#'   `x`/`y` is the fitted value and the bar extends toward the observed
#'   value. Incompatible with `stat = "error"`. Default `FALSE`.
#' @param na.rm If `FALSE`, missing values are removed with a warning.
#' @param show.legend Logical. Should this layer be included in the legends?
#' @param inherit.aes If `FALSE`, overrides the default aesthetics.
#'
#' @section Aesthetics:
#' `geom_error()` requires `x`, `y`, and one of:
#' - `error` — symmetric half-width applied along the non-categorical axis.
#' - `error_neg` **and** `error_pos` — asymmetric; the bar extends
#'   `error_neg` in the negative direction and `error_pos` in the positive
#'   direction along the non-categorical axis. For a one-sided bar, set
#'   the unused side to `NA` — the cap, stem, and shared-bound cap on
#'   that side are all suppressed.
#'
#' Mixing `error` with `error_neg` / `error_pos` is an error, as is
#' providing only one of the asymmetric pair.
#'
#' Fixed per-side styling can be supplied through `...` with `_neg` and
#' `_pos` suffixes for `colour`, `fill`, `linewidth`, `linetype`, `alpha`,
#' and `width`.
#' These are fixed scalar parameters, not mapped aesthetics.
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
#' # Asymmetric: bar extends drat/2 below and drat above each point
#' ggplot(mtcars, aes(factor(cyl), mpg)) +
#'   geom_point() +
#'   geom_error(aes(error_neg = drat / 2, error_pos = drat))
#'
#' # Style the negative and positive halves separately
#' ggplot(mtcars, aes(factor(cyl), mpg)) +
#'   geom_point() +
#'   geom_error(
#'     aes(error_neg = drat / 2, error_pos = drat),
#'     colour_neg = "steelblue",
#'     colour_pos = "firebrick"
#'   )
#'
#' @export
geom_error <- function(mapping = NULL, data = NULL,
                       stat = "identity", position = "identity",
                       ...,
                       error_geom = "errorbar",
                       orientation = NA,
                       sign_aware = FALSE,
                       na.rm = FALSE,
                       show.legend = NA,
                       inherit.aes = TRUE) {
  call <- rlang::caller_env()
  params <- list(...)
  check_error_geom(error_geom, call = call)
  check_orientation(orientation, call = call)
  check_per_side_params(params, call = call)

  use_stat_error <- is.character(stat) && identical(stat, "error")
  if (use_stat_error && isTRUE(sign_aware)) {
    cli::cli_abort(
      c(
        "{.arg sign_aware} cannot be combined with \\
         {.code stat = \"error\"}.",
        i = "{.fn stat_error} summarises raw data; there is no sign to route.",
        i = "Drop one of {.arg sign_aware} or {.code stat = \"error\"}."
      ),
      class = "ggerror_error_sign_aware_with_stat",
      call  = call
    )
  }
  if (use_stat_error) {
    stat_obj <- StatError
    geom_obj <- GeomErrorStat
    extra    <- list(fun = params$fun %||% "mean_se")
    params$fun <- NULL
  } else {
    stat_obj <- stat
    geom_obj <- GeomError
    extra    <- list()
  }

  ggplot2::layer(
    geom        = geom_obj,
    mapping     = mapping,
    data        = data,
    stat        = stat_obj,
    position    = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params      = c(list(
      error_geom  = error_geom,
      orientation = orientation,
      sign_aware  = isTRUE(sign_aware),
      na.rm       = na.rm
    ), extra, params)
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

  required_aes = c("x", "y", "error|error_pos|error_neg"),

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

  extra_params = c(
    "na.rm", "error_geom", "orientation", "sign_aware",
    "zero_threshold", "silent_zero_warning",
    per_side_param_names
  ),

  setup_params = function(data, params) {
    params$error_geom  <- params$error_geom %||% "errorbar"
    params$orientation <- infer_orientation(data, params)
    params$flipped_aes <- params$orientation == "y"
    params
  },

  setup_data = function(data, params) {
    check_error_aes_combination(data)

    # Coerce error columns to double so logical NA (from aes(error_neg = NA))
    # is accepted by the non-negative check.
    for (nm in c("error", "error_neg", "error_pos")) {
      if (nm %in% names(data) && !is.numeric(data[[nm]])) {
        data[[nm]] <- as.double(data[[nm]])
      }
    }

    check_deprecated_zero_side(
      data,
      zero_threshold      = params$zero_threshold      %||% 1e-8,
      silent_zero_warning = params$silent_zero_warning %||% FALSE
    )

    if (isTRUE(params$sign_aware) && "error" %in% names(data)) {
      e <- data$error
      data$error_neg <- ifelse(!is.na(e) & e < 0, -e, NA_real_)
      data$error_pos <- ifelse(!is.na(e) & e > 0,  e, NA_real_)
      data$error <- NULL
    }

    check_error_aes(data)

    data$flipped_aes <- params$flipped_aes
    data <- ggplot2::flip_data(data, params$flipped_aes)

    # Error range along canonical y-axis. NA on a side -> suppressed cap/stem.
    if ("error" %in% names(data)) {
      data$ymin <- data$y - data$error
      data$ymax <- data$y + data$error
      data$error <- NULL
    } else {
      data$ymin <- ifelse(is.na(data$error_neg), NA_real_,
                          data$y - data$error_neg)
      data$ymax <- ifelse(is.na(data$error_pos), NA_real_,
                          data$y + data$error_pos)
      data$error_neg <- NULL
      data$error_pos <- NULL
    }

    # Cap/box horizontal bounds from width. `params[["width"]]` uses exact
    # matching so per-side params like `width_neg` don't leak via `$` partial
    # matching.
    width <- data$width %||% params[["width"]] %||%
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
                        na.rm       = FALSE,
                        colour_neg = NULL, colour_pos = NULL,
                        fill_neg = NULL, fill_pos = NULL,
                        linewidth_neg = NULL, linewidth_pos = NULL,
                        linetype_neg = NULL, linetype_pos = NULL,
                        alpha_neg = NULL, alpha_pos = NULL,
                        width_neg = NULL, width_pos = NULL) {
    overrides <- list(
      colour_neg = colour_neg, colour_pos = colour_pos,
      fill_neg = fill_neg, fill_pos = fill_pos,
      linewidth_neg = linewidth_neg, linewidth_pos = linewidth_pos,
      linetype_neg = linetype_neg, linetype_pos = linetype_pos,
      alpha_neg = alpha_neg, alpha_pos = alpha_pos,
      width_neg = width_neg, width_pos = width_pos
    )

    has_per_side <- any(!vapply(overrides, is.null, logical(1)))
    has_na_side  <- any(is.na(data$ymin) | is.na(data$ymax))

    if (!has_per_side && !has_na_side) {
      return(dispatch_error_geom(
        error_geom = error_geom,
        data = data,
        panel_params = panel_params,
        coord = coord,
        flipped_aes = flipped_aes,
        lineend = lineend,
        linejoin = linejoin,
        fatten = fatten,
        na.rm = na.rm
      ))
    }

    draw_per_side(
      data = data,
      overrides = overrides,
      error_geom = error_geom,
      flipped_aes = flipped_aes,
      panel_params = panel_params,
      coord = coord,
      lineend = lineend,
      linejoin = linejoin,
      fatten = fatten,
      na.rm = na.rm
    )
  }
)

#' @keywords internal
#' @noRd
dispatch_error_geom <- function(error_geom, data, panel_params, coord,
                                flipped_aes, lineend, linejoin, fatten,
                                na.rm) {
  if (!nrow(data)) return(grid::nullGrob())

  base <- list(
    data = data,
    panel_params = panel_params,
    coord = coord,
    flipped_aes = flipped_aes,
    lineend = lineend
  )

  switch(
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
}

#' @keywords internal
#' @noRd
draw_per_side <- function(data, overrides, error_geom, flipped_aes,
                          panel_params, coord, lineend, linejoin,
                          fatten, na.rm) {
  data <- ggplot2::flip_data(data, flipped_aes)

  if (error_geom == "errorbar") {
    return(draw_per_side_errorbar(
      data = data,
      overrides = overrides,
      flipped_aes = flipped_aes,
      panel_params = panel_params,
      coord = coord,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm
    ))
  }

  if (error_geom == "pointrange") {
    return(draw_per_side_pointrange(
      data = data,
      overrides = overrides,
      flipped_aes = flipped_aes,
      panel_params = panel_params,
      coord = coord,
      lineend = lineend,
      linejoin = linejoin,
      fatten = fatten,
      na.rm = na.rm
    ))
  }

  neg <- ggplot2::flip_data(
    build_per_side_data(data, overrides, "neg"),
    flipped_aes
  )
  pos <- ggplot2::flip_data(
    build_per_side_data(data, overrides, "pos"),
    flipped_aes
  )

  grid::grobTree(
    dispatch_error_geom(
      error_geom = error_geom,
      data = neg,
      panel_params = panel_params,
      coord = coord,
      flipped_aes = flipped_aes,
      lineend = lineend,
      linejoin = linejoin,
      fatten = fatten,
      na.rm = na.rm
    ),
    dispatch_error_geom(
      error_geom = error_geom,
      data = pos,
      panel_params = panel_params,
      coord = coord,
      flipped_aes = flipped_aes,
      lineend = lineend,
      linejoin = linejoin,
      fatten = fatten,
      na.rm = na.rm
    )
  )
}

#' @keywords internal
#' @noRd
build_per_side_data <- function(data, overrides, side) {
  bound <- if (identical(side, "neg")) "ymin" else "ymax"
  half  <- data[!is.na(data[[bound]]), , drop = FALSE]
  if (!nrow(half)) return(half)

  if (identical(side, "neg")) {
    half$ymax <- half$y
  } else {
    half$ymin <- half$y
  }

  for (aes_name in c("colour", "fill", "linewidth", "linetype", "alpha")) {
    value <- overrides[[paste0(aes_name, "_", side)]]
    if (!is.null(value)) {
      half[[aes_name]] <- value
    }
  }

  width <- overrides[[paste0("width_", side)]]
  if (!is.null(width)) {
    half$xmin <- half$x - width / 2
    half$xmax <- half$x + width / 2
  }

  half
}

#' @keywords internal
#' @noRd
draw_per_side_errorbar <- function(data, overrides, flipped_aes,
                                   panel_params, coord, lineend,
                                   linejoin, na.rm) {
  neg <- ggplot2::flip_data(
    build_errorbar_segments(data, overrides, "neg"),
    flipped_aes
  )
  pos <- ggplot2::flip_data(
    build_errorbar_segments(data, overrides, "pos"),
    flipped_aes
  )

  grid::grobTree(
    draw_segment_panel(
      neg,
      panel_params = panel_params,
      coord = coord,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm
    ),
    draw_segment_panel(
      pos,
      panel_params = panel_params,
      coord = coord,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm
    )
  )
}

#' @keywords internal
#' @noRd
build_errorbar_segments <- function(data, overrides, side) {
  bound <- if (identical(side, "neg")) "ymin" else "ymax"
  keep  <- !is.na(data[[bound]])
  data  <- data[keep, , drop = FALSE]
  if (!nrow(data)) return(data.frame())

  styled <- build_per_side_data(data, overrides, side)
  width  <- resolve_per_side_width(data, overrides, side)

  stem <- styled
  stem$xend <- styled$x
  if (identical(side, "neg")) {
    stem$y <- styled$ymin
    stem$yend <- styled$y
  } else {
    stem$y <- styled$y
    stem$yend <- styled$ymax
  }

  cap <- styled
  cap$x <- styled$x - width / 2
  cap$xend <- styled$x + width / 2
  if (identical(side, "neg")) {
    cap$y <- styled$ymin
    cap$yend <- styled$ymin
  } else {
    cap$y <- styled$ymax
    cap$yend <- styled$ymax
  }

  combine_non_zero_segments(stem, cap)
}

#' @keywords internal
#' @noRd
resolve_per_side_width <- function(data, overrides, side) {
  width <- overrides[[paste0("width_", side)]]
  if (is.null(width)) {
    data$xmax - data$xmin
  } else {
    rep(width, nrow(data))
  }
}

#' @keywords internal
#' @noRd
combine_non_zero_segments <- function(...) {
  segments <- Filter(length, list(...))
  if (!length(segments)) {
    return(data.frame())
  }

  data <- do.call(rbind, segments)
  data[!(data$x == data$xend & data$y == data$yend), , drop = FALSE]
}

#' @keywords internal
#' @noRd
draw_segment_panel <- function(data, panel_params, coord, lineend,
                               linejoin, na.rm) {
  if (!nrow(data)) {
    return(grid::nullGrob())
  }

  ggplot2::GeomSegment$draw_panel(
    data = data,
    panel_params = panel_params,
    coord = coord,
    lineend = lineend,
    linejoin = linejoin,
    na.rm = na.rm
  )
}

#' @keywords internal
#' @noRd
draw_per_side_pointrange <- function(data, overrides, flipped_aes,
                                     panel_params, coord, lineend,
                                     linejoin, fatten, na.rm) {
  neg <- ggplot2::flip_data(
    build_per_side_data(data, overrides, "neg"),
    flipped_aes
  )
  pos <- ggplot2::flip_data(
    build_per_side_data(data, overrides, "pos"),
    flipped_aes
  )
  point <- ggplot2::flip_data(data, flipped_aes)
  point$size <- point$size * (fatten %||% 4)

  grid::grobTree(
    dispatch_error_geom(
      error_geom = "linerange",
      data = neg,
      panel_params = panel_params,
      coord = coord,
      flipped_aes = flipped_aes,
      lineend = lineend,
      linejoin = linejoin,
      fatten = fatten,
      na.rm = na.rm
    ),
    dispatch_error_geom(
      error_geom = "linerange",
      data = pos,
      panel_params = panel_params,
      coord = coord,
      flipped_aes = flipped_aes,
      lineend = lineend,
      linejoin = linejoin,
      fatten = fatten,
      na.rm = na.rm
    ),
    ggplot2::GeomPoint$draw_panel(
      data = point,
      panel_params = panel_params,
      coord = coord,
      na.rm = na.rm
    )
  )
}
