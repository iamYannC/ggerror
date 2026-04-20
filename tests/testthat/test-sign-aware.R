# sign_aware = TRUE routes signed `error` into one-sided bars per row.
#
# Contract:
#  * Positive `error` -> error_pos (= error); opposite side NA.
#  * Negative `error` -> error_neg (= abs(error)); opposite side NA.
#  * Zero / NA `error` -> both NA (no bar for that row).
#  * Works across all four error_geom values.
#  * Incompatible with `stat = "error"` (summary stats have no sign).
#  * NA auto-suppresses the cap/stem on that side — no warnings.

# ---- splitting ------------------------------------------------------------

test_that("sign_aware routes positive error to ymax side", {
  dat <- data.frame(x = 1:3, y = 10, e = c(2, 3, 4))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), sign_aware = TRUE, orientation = "x")
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_true(all(is.na(ld$ymin)))
  expect_equal(ld$ymax, c(12, 13, 14))
})

test_that("sign_aware routes negative error to ymin side", {
  dat <- data.frame(x = 1:3, y = 10, e = c(-2, -3, -4))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), sign_aware = TRUE, orientation = "x")
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_equal(ld$ymin, c(8, 7, 6))
  expect_true(all(is.na(ld$ymax)))
})

test_that("sign_aware handles mixed signs per row", {
  dat <- data.frame(x = 1:3, y = 10, e = c(-2, 3, 0))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), sign_aware = TRUE, orientation = "x")
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_equal(ld$ymin[1], 8);  expect_true(is.na(ld$ymax[1]))
  expect_true(is.na(ld$ymin[2])); expect_equal(ld$ymax[2], 13)
  expect_true(is.na(ld$ymin[3])); expect_true(is.na(ld$ymax[3]))
})

test_that("sign_aware treats NA error as both-sides NA", {
  dat <- data.frame(x = 1:3, y = 10, e = c(-2, NA_real_, 4))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), sign_aware = TRUE, orientation = "x")
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_equal(ld$ymin[1], 8); expect_true(is.na(ld$ymax[1]))
  expect_true(is.na(ld$ymin[2])); expect_true(is.na(ld$ymax[2]))
  expect_true(is.na(ld$ymin[3])); expect_equal(ld$ymax[3], 14)
})

# ---- negative error when sign_aware = FALSE (existing behaviour) ---------

test_that("negative error with sign_aware = FALSE still errors", {
  dat <- data.frame(x = 1:3, y = 10, e = c(-2, 3, 4))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error = e), orientation = "x")
  expect_error(
    ggplot2::ggplot_build(p),
    class = "ggerror_error_negative_error_aes"
  )
})

# ---- incompatibility with stat_error --------------------------------------

test_that("sign_aware + stat = 'error' is incompatible", {
  dat <- data.frame(x = factor(letters[1:3]), y = 1:3)
  expect_error(
    ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
      geom_error(stat = "error", sign_aware = TRUE, orientation = "x"),
    class = "ggerror_error_sign_aware_with_stat"
  )
})

# ---- rendering with NA suppression ---------------------------------------

test_that("sign_aware renders cleanly for every error_geom", {
  dat <- data.frame(x = 1:4, y = 10, e = c(-2, 3, -1, 4))
  for (type in c("errorbar", "linerange", "crossbar", "pointrange")) {
    p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
      ggplot2::geom_point() +
      geom_error(ggplot2::aes(error = e), sign_aware = TRUE,
                 error_geom = type, orientation = "x")
    expect_no_error(ggplot2::ggplot_gtable(ggplot2::ggplot_build(p)))
  }
})

test_that("aes(error_neg = NA, error_pos = ...) is the one-sided idiom", {
  dat <- data.frame(x = 1:3, y = 10, e = c(1, 2, 3))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = NA, error_pos = e), orientation = "x")
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_true(all(is.na(ld$ymin)))
  expect_equal(ld$ymax, 10 + 1:3)
  expect_no_error(ggplot2::ggplot_gtable(ggplot2::ggplot_build(p)))
})
