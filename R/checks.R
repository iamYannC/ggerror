#' @keywords internal
#' @noRd
check_error_geom <- function(error_geom, call = rlang::caller_env()) {
  valid <- c("errorbar", "linerange", "crossbar", "pointrange")
  if (!is.character(error_geom) || length(error_geom) != 1L ||
      !error_geom %in% valid) {
    cli::cli_abort(
      "{.arg error_geom} must be one of {.or {.val {valid}}}, \\
       not {.val {error_geom}}.",
      class = "ggerror_error_bad_error_geom",
      call  = call
    )
  }
  invisible(error_geom)
}

#' @keywords internal
#' @noRd
check_orientation <- function(orientation, call = rlang::caller_env()) {
  if (length(orientation) != 1L) {
    cli::cli_abort(
      "{.arg orientation} must be length 1, not length {length(orientation)}.",
      class = "ggerror_error_bad_orientation",
      call  = call
    )
  }
  if (is.na(orientation)) {
    return(invisible(orientation))
  }
  if (!is.character(orientation) || !orientation %in% c("x", "y")) {
    cli::cli_abort(
      "{.arg orientation} must be {.val x}, {.val y}, or {.code NA}, \\
       not {.val {orientation}}.",
      class = "ggerror_error_bad_orientation",
      call  = call
    )
  }
  invisible(orientation)
}

#' @keywords internal
#' @noRd
check_pinned_error_geom <- function(is_missing, fn, type,
                                    call = rlang::caller_env()) {
  if (is_missing) {
    return(invisible(NULL))
  }
  cli::cli_abort(
    c(
      "{.fn {fn}} pins {.arg error_geom} to {.val {type}}; do not pass it.",
      i = "Use {.fn geom_error} if you need to choose {.arg error_geom} at call time."
    ),
    class = "ggerror_error_pinned_error_geom",
    call  = call
  )
}

#' @keywords internal
#' @noRd
per_side_param_names <- c(
  "colour_neg", "colour_pos",
  "fill_neg", "fill_pos",
  "linewidth_neg", "linewidth_pos",
  "linetype_neg", "linetype_pos",
  "alpha_neg", "alpha_pos",
  "width_neg", "width_pos"
)

#' @keywords internal
#' @noRd
check_per_side_params <- function(params, call = rlang::caller_env()) {
  for (nm in intersect(names(params), per_side_param_names)) {
    value <- params[[nm]]

    if (is.null(value)) {
      next
    }

    if (!rlang::is_scalar_atomic(value)) {
      cli::cli_abort(
        c(
          "{.arg {nm}} must be a single fixed value, not a vectorised aesthetic.",
          i = "Map aesthetics inside {.fn aes}, or pass one scalar value here."
        ),
        class = "ggerror_error_bad_per_side_param",
        call = call
      )
    }

    if (nm %in% c("width_neg", "width_pos") &&
        (!is.numeric(value) || is.na(value) || value < 0)) {
      cli::cli_abort(
        "{.arg {nm}} must be a single non-negative numeric value.",
        class = "ggerror_error_bad_per_side_param",
        call = call
      )
    }
  }

  invisible(params)
}

#' @keywords internal
#' @noRd
check_error_aes_combination <- function(data) {
  has_sym  <- "error"     %in% names(data)
  has_neg  <- "error_neg" %in% names(data)
  has_pos  <- "error_pos" %in% names(data)

  if (has_sym && (has_neg || has_pos)) {
    cli::cli_abort(
      c(
        "Cannot combine {.field error} with \\
         {.field error_neg} / {.field error_pos}.",
        i = "Use {.field error} for symmetric errors,",
        i = "or {.field error_neg} + {.field error_pos} for asymmetric errors."
      ),
      class = "ggerror_error_conflicting_error_aes"
    )
  }

  if (has_neg != has_pos) {
    provided <- if (has_pos) "error_pos" else "error_neg"
    missing_ <- if (has_pos) "error_neg" else "error_pos"
    cli::cli_abort(
      c(
        "{.field {provided}} was supplied without {.field {missing_}}.",
        i = "For symmetric errors, use {.field error} instead.",
        i = "For a one-sided bar, set {.field {missing_}} to {.val {0}} explicitly."
      ),
      class = "ggerror_error_incomplete_asym_error_aes"
    )
  }

  invisible(data)
}

#' @keywords internal
#' @noRd
check_nonneg_aes <- function(values, aes_name) {
  if (!is.numeric(values)) {
    cli::cli_abort(
      "{.field {aes_name}} aesthetic must be numeric, \\
       not {.cls {class(values)[1]}}.",
      class = "ggerror_error_bad_error_aes"
    )
  }
  neg <- !is.na(values) & values < 0
  if (any(neg)) {
    cli::cli_abort(
      c(
        "{.field {aes_name}} aesthetic must be non-negative.",
        i = "Found {sum(neg)} negative value{?s}."
      ),
      class = "ggerror_error_negative_error_aes"
    )
  }
  invisible(values)
}

#' @keywords internal
#' @noRd
check_deprecated_zero_side <- function(data, zero_threshold = 1e-8,
                                       silent_zero_warning = FALSE) {
  if (isTRUE(silent_zero_warning)) return(invisible(data))

  for (nm in c("error_neg", "error_pos")) {
    if (!nm %in% names(data)) next
    v <- data[[nm]]
    v <- v[!is.na(v)]
    if (!length(v)) next
    if (all(abs(v) <= zero_threshold)) {
      opposite <- if (nm == "error_neg") "error_pos" else "error_neg"
      lifecycle::deprecate_warn(
        when = "1.0.0",
        what = I(sprintf("Using `0` in %s to signal a one-sided bar", nm)),
        with = I(sprintf("`NA` in aes(%s)", nm)),
        details = c(
          i = sprintf(
            "Replace the zero column with `NA`: aes(%s = NA, %s = ...).",
            nm, opposite
          ),
          i = "Silence this warning with `silent_zero_warning = TRUE`, \\
               or tune with `zero_threshold`."
        )
      )
    }
  }
  invisible(data)
}

#' @keywords internal
#' @noRd
check_error_aes <- function(data) {
  for (nm in c("error", "error_neg", "error_pos")) {
    if (nm %in% names(data)) {
      check_nonneg_aes(data[[nm]], nm)
    }
  }
  invisible(data)
}
