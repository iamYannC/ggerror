# Deprecation: `0` -> `NA` for one-sided bars.
#
# A uniformly-zero `error_neg` or `error_pos` column is the pre-v1.0 way to
# get a one-sided bar. v1.0 introduces `NA` as the cleaner idiom and
# warns via lifecycle::deprecate_warn() on detection. The old behaviour
# (0 + width_neg = 0) keeps rendering — only warns. zero_threshold (default
# 1e-8) tunes what counts as "zero"; silent_zero_warning = TRUE suppresses.

test_that("uniformly-zero error_neg triggers deprecation", {
  dat <- data.frame(x = 1:3, y = 10, en = 0, ep = 1:3)
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x")
  expect_warning(
    ggplot2::ggplot_build(p),
    class = "lifecycle_warning_deprecated"
  )
})

test_that("uniformly-zero error_pos triggers deprecation", {
  dat <- data.frame(x = 1:3, y = 10, en = 1:3, ep = 0)
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x")
  expect_warning(
    ggplot2::ggplot_build(p),
    class = "lifecycle_warning_deprecated"
  )
})

test_that("non-zero side does not trigger deprecation", {
  dat <- data.frame(x = 1:3, y = 10, en = 2, ep = 1:3)
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x")
  expect_no_warning(ggplot2::ggplot_build(p))
})

test_that("silent_zero_warning = TRUE suppresses the deprecation", {
  dat <- data.frame(x = 1:3, y = 10, en = 0, ep = 1:3)
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x", silent_zero_warning = TRUE)
  expect_no_warning(ggplot2::ggplot_build(p))
})

test_that("zero_threshold governs what counts as zero", {
  # 1e-10 is within default zero_threshold = 1e-8 -> warns.
  dat <- data.frame(x = 1:3, y = 10, en = 1e-10, ep = 1:3)
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x")
  expect_warning(
    ggplot2::ggplot_build(p),
    class = "lifecycle_warning_deprecated"
  )

  # 1e-6 exceeds default zero_threshold -> no warning.
  dat2 <- data.frame(x = 1:3, y = 10, en = 1e-6, ep = 1:3)
  p2 <- ggplot2::ggplot(dat2, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x")
  expect_no_warning(ggplot2::ggplot_build(p2))
})

test_that("tightening zero_threshold removes the warning", {
  dat <- data.frame(x = 1:3, y = 10, en = 1e-10, ep = 1:3)
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x", zero_threshold = 1e-12)
  expect_no_warning(ggplot2::ggplot_build(p))
})

test_that("deprecated zero bar still renders (0 keeps working)", {
  dat <- data.frame(x = 1:3, y = 10, en = 0, ep = 1:3)
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    geom_error(ggplot2::aes(error_neg = en, error_pos = ep),
               orientation = "x", silent_zero_warning = TRUE)
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_equal(ld$ymin, rep(10, 3))
  expect_equal(ld$ymax, 10 + 1:3)
})
