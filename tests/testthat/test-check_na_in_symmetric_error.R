# check_na_in_symmetric_error(): warns with row indices when symmetric
# `error` has NAs. Classed `ggerror_warn_error_na`. Bypassed when
# sign_aware = TRUE (NA is meaningful there).

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

test_that("sign_aware = TRUE bypasses the NA warning", {
  dat <- data.frame(x = 1:3, y = 10, e = c(-2, NA_real_, 4))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), sign_aware = TRUE, orientation = "x")
  expect_no_warning(ggplot2::ggplot_build(p))
})
