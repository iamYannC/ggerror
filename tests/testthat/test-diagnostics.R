# Diagnostics added in v1.0.0:
#  * NA in symmetric `error` -> warning (classed, row indices).
#  * Negative values in any error aesthetic when sign_aware = FALSE ->
#    hard error (classed, row indices, suggests sign_aware / abs()).
#  * Row indices truncate to first 5.

# ---- 4a: NA warning for symmetric error -----------------------------------

test_that("NA in symmetric error emits a classed warning with row indices", {
  dat <- data.frame(x = 1:4, y = 10, e = c(1, NA, 3, NA))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), orientation = "x")
  expect_warning(
    ggplot2::ggplot_build(p),
    class = "ggerror_warn_error_na"
  )
})

test_that("NA warning cites up to 5 row indices", {
  dat <- data.frame(x = 1:8, y = 10,
                    e = c(NA, 1, NA, 2, NA, 3, NA, 4))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), orientation = "x")
  expect_warning(
    ggplot2::ggplot_build(p),
    class  = "ggerror_warn_error_na",
    regexp = "1.*3"
  )
})

test_that("no NA warning when error has no NAs", {
  dat <- data.frame(x = 1:3, y = 10, e = c(1, 2, 3))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), orientation = "x")
  expect_no_warning(ggplot2::ggplot_build(p))
})

# ---- 4b: negative values + sign_aware = FALSE -----------------------------

test_that("negative error reports row indices and suggests fixes", {
  dat <- data.frame(x = 1:5, y = 10, e = c(1, -2, 3, -4, 5))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), orientation = "x")
  expect_error(
    ggplot2::ggplot_build(p),
    class  = "ggerror_error_negative_error_aes",
    regexp = "2"
  )
  expect_error(
    ggplot2::ggplot_build(p),
    class  = "ggerror_error_negative_error_aes",
    regexp = "4"
  )
  expect_error(
    ggplot2::ggplot_build(p),
    class  = "ggerror_error_negative_error_aes",
    regexp = "sign_aware|abs"
  )
})

test_that("negative value row indices truncate to first 5", {
  dat <- data.frame(x = 1:10, y = 10, e = -(1:10))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), orientation = "x")
  # Positive assertion: first five rows appear.
  expect_error(
    ggplot2::ggplot_build(p),
    class  = "ggerror_error_negative_error_aes",
    regexp = "5 more"
  )
})

test_that("negative error_neg / error_pos also errors with row indices", {
  dat <- data.frame(x = 1:3, y = 10, en = c(-1, 2, 3), ep = c(1, 2, 3))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x")
  expect_error(
    ggplot2::ggplot_build(p),
    class = "ggerror_error_negative_error_aes"
  )
})

test_that("sign_aware = TRUE bypasses the negative-value error", {
  dat <- data.frame(x = 1:3, y = 10, e = c(-1, 2, -3))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), sign_aware = TRUE,
               orientation = "x")
  expect_no_error(ggplot2::ggplot_build(p))
})
