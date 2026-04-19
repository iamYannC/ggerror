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
check_error_aes <- function(error) {
  if (!is.numeric(error)) {
    cli::cli_abort(
      "{.field error} aesthetic must be numeric, \\
       not {.cls {class(error)[1]}}.",
      class = "ggerror_error_bad_error_aes"
    )
  }

  neg <- !is.na(error) & error < 0
  if (any(neg)) {
    cli::cli_abort(
      c(
        "{.field error} aesthetic must be non-negative.",
        i = "Found {sum(neg)} negative value{?s}.",
        i = "For asymmetric ranges, use {.arg error_lower} / {.arg error_upper} \\
             (planned for v0.2)."
      ),
      class = "ggerror_error_negative_error_aes"
    )
  }
  invisible(error)
}
