# stat_error() — end-to-end behaviour of the summarising layer.
#
# Unit tests for the internal helpers live alongside them:
#   test-resolve_stat_fun.R
#   test-validate_stat_fun_return.R
#   test-mean_cl_normal_internal.R
#   test-call_stat_fun.R

# ---- default fun -----------------------------------------------------------

test_that("stat_error(fun = 'mean_se') produces mean/SE per group", {
  set.seed(1)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 10)),
    y = c(rnorm(10, 1), rnorm(10, 2), rnorm(10, 3))
  )
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error()
  ld <- ggplot2::ggplot_build(p)$data[[1]]

  expect_identical(nrow(ld), 3L)

  ref <- do.call(rbind, lapply(split(dat$y, dat$x), ggplot2::mean_se))
  expect_equal(sort(ld$y),    sort(ref$y),    tolerance = 1e-10)
  expect_equal(sort(ld$ymin), sort(ref$ymin), tolerance = 1e-10)
  expect_equal(sort(ld$ymax), sort(ref$ymax), tolerance = 1e-10)
})

# ---- mean_ci ---------------------------------------------------------------

test_that("stat_error(fun = 'mean_ci') uses the internal normal CI", {
  set.seed(2)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 20)),
    y = rnorm(60)
  )
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error(fun = "mean_ci")
  ld <- ggplot2::ggplot_build(p)$data[[1]]

  ref <- do.call(rbind, lapply(split(dat$y, dat$x),
                               ggerror:::mean_cl_normal_internal))
  expect_equal(sort(ld$y),    sort(ref$y),    tolerance = 1e-10)
  expect_equal(sort(ld$ymin), sort(ref$ymin), tolerance = 1e-10)
  expect_equal(sort(ld$ymax), sort(ref$ymax), tolerance = 1e-10)
})

# ---- conf.int --------------------------------------------------------------

test_that("stat_error(conf.int = 0.9) narrows the CI on mean_ci", {
  set.seed(10)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 15)),
    y = rnorm(45)
  )

  build <- function(level) {
    p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
      stat_error(fun = "mean_ci", conf.int = level)
    ggplot2::ggplot_build(p)$data[[1]]
  }

  at_95 <- build(0.95)
  at_90 <- build(0.90)

  # A 90% CI is strictly narrower than a 95% CI for the same data.
  expect_true(all(at_90$ymax - at_90$ymin < at_95$ymax - at_95$ymin))
})

test_that("stat_error(conf.int = ...) is harmless for mean_se", {
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 10)),
    y = rnorm(30)
  )
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    stat_error(conf.int = 0.8)
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("stat_error forwards conf.int to a custom fun that declares it", {
  my_fn <- function(y, conf.int = 0.95) {
    n  <- length(y); m <- mean(y); se <- stats::sd(y) / sqrt(n)
    tq <- stats::qt((1 + conf.int) / 2, df = n - 1)
    data.frame(y = m, ymin = m - tq * se, ymax = m + tq * se)
  }
  set.seed(11)
  dat <- data.frame(x = factor(rep(letters[1:3], each = 10)), y = rnorm(30))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    stat_error(fun = my_fn, conf.int = 0.80)
  ld <- ggplot2::ggplot_build(p)$data[[1]]

  ref <- do.call(rbind, lapply(split(dat$y, dat$x), my_fn, conf.int = 0.80))
  expect_equal(sort(ld$ymin), sort(ref$ymin), tolerance = 1e-10)
})

test_that("stat_error rejects out-of-range conf.int at construction", {
  expect_error(stat_error(conf.int = 1.5),
               class = "ggerror_error_bad_conf_int")
  expect_error(stat_error(conf.int = 0),
               class = "ggerror_error_bad_conf_int")
  expect_error(stat_error(conf.int = c(0.9, 0.95)),
               class = "ggerror_error_bad_conf_int")
})

# ---- na.rm ----------------------------------------------------------------

test_that("stat_error(na.rm = TRUE) drops NAs before summarising", {
  dat <- data.frame(
    x = factor(rep(letters[1:2], each = 5)),
    y = c(1, 2, NA, 4, 5, 6, 7, 8, 9, 10)
  )
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    stat_error(na.rm = TRUE)
  ld <- ggplot2::ggplot_build(p)$data[[1]]

  ref <- do.call(rbind, lapply(split(dat$y, dat$x),
                               function(y) ggplot2::mean_se(y[!is.na(y)])))
  expect_equal(sort(ld$y), sort(ref$y), tolerance = 1e-10)
})

# ---- custom function ------------------------------------------------------

test_that("stat_error accepts a custom fun.data-style function", {
  my_fn <- function(y) {
    data.frame(
      y    = median(y),
      ymin = stats::quantile(y, 0.25, names = FALSE),
      ymax = stats::quantile(y, 0.75, names = FALSE)
    )
  }
  set.seed(3)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 10)),
    y = rnorm(30)
  )
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error(fun = my_fn)
  ld <- ggplot2::ggplot_build(p)$data[[1]]

  ref <- do.call(rbind, lapply(split(dat$y, dat$x), my_fn))
  expect_equal(sort(ld$y),    sort(ref$y),    tolerance = 1e-10)
  expect_equal(sort(ld$ymin), sort(ref$ymin), tolerance = 1e-10)
  expect_equal(sort(ld$ymax), sort(ref$ymax), tolerance = 1e-10)
})

# ---- dual entry points ----------------------------------------------------

test_that("geom_error(stat = 'error') is equivalent to stat_error()", {
  set.seed(4)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 10)),
    y = rnorm(30)
  )

  via_stat <- ggplot2::ggplot_build(
    ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error()
  )$data[[1]]

  via_geom <- ggplot2::ggplot_build(
    ggplot2::ggplot(dat, ggplot2::aes(x, y)) + geom_error(stat = "error")
  )$data[[1]]

  expect_equal(via_stat[sort(names(via_stat))],
               via_geom[sort(names(via_geom))])
})

# ---- composition with error_geom ------------------------------------------

test_that("stat_error composes with all error_geom values", {
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 8)),
    y = rnorm(24)
  )
  for (type in c("errorbar", "linerange", "crossbar", "pointrange")) {
    p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
      stat_error(error_geom = type)
    expect_no_error(ggplot2::ggplot_build(p))
  }
})

test_that("stat_error works via the pinned wrappers through stat = 'error'", {
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 8)),
    y = rnorm(24)
  )
  for (type in c("linerange", "crossbar", "pointrange")) {
    wrapper <- get(paste0("geom_error_", type), envir = asNamespace("ggerror"))
    p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) + wrapper(stat = "error")
    layer <- p$layers[[1]]
    expect_identical(layer$geom_params$error_geom, type)
    expect_no_error(ggplot2::ggplot_build(p))
  }
})

# ---- orientation ----------------------------------------------------------

test_that("stat_error summarises along the numeric axis when x is discrete", {
  set.seed(5)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 10)),
    y = rnorm(30)
  )
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error()
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_true(all(c("ymin", "ymax") %in% names(ld)))
})

test_that("stat_error summarises along the numeric axis when y is discrete", {
  set.seed(6)
  dat <- data.frame(
    x = rnorm(30),
    y = factor(rep(letters[1:3], each = 10))
  )
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error()
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_true(all(c("xmin", "xmax") %in% names(ld)))
})
