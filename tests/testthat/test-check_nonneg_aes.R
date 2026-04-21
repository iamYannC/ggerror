# check_nonneg_aes(): errors with row indices when an error aesthetic has
# negative values and sign_aware = FALSE. Row indices truncate to first 5
# with a `(+ N more)` suffix. Suggests sign_aware = TRUE / abs().

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
