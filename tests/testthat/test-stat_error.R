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

test_that("stat_error(conf.int = ..., fun = 'mean_se') warns and still builds", {
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 10)),
    y = rnorm(30)
  )
  p <- suppressWarnings(
    ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error(conf.int = 0.8)
  )
  # Build succeeds even though conf.int was effectively ignored.
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("explicit conf.int with fun = 'mean_se' fires a classed warning", {
  expect_warning(
    stat_error(conf.int = 0.9),
    class = "ggerror_warn_conf_int_ignored"
  )
})

test_that("explicit conf.int with fun = 'mean_ci' does not warn", {
  expect_no_warning(stat_error(fun = "mean_ci", conf.int = 0.9))
})

test_that("explicit conf.int with a custom fun does not warn", {
  my_fn <- function(y, conf.int = 0.95) {
    data.frame(y = mean(y), ymin = conf.int, ymax = conf.int)
  }
  expect_no_warning(stat_error(fun = my_fn, conf.int = 0.9))
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

test_that("stat_error forwards ... args matching custom fun's formals", {
  iqr_fun <- function(y, type = 7) {
    data.frame(
      y    = median(y),
      ymin = stats::quantile(y, 0.25, type = type, names = FALSE),
      ymax = stats::quantile(y, 0.75, type = type, names = FALSE)
    )
  }
  set.seed(7)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 10)),
    y = rnorm(30)
  )
  build <- function(type) {
    p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
      stat_error(fun = iqr_fun, type = type)
    ggplot2::ggplot_build(p)$data[[1]]
  }
  ld1 <- build(1)
  ld7 <- build(7)
  # Different quantile types should produce different bounds.
  expect_false(isTRUE(all.equal(sort(ld1$ymin), sort(ld7$ymin))))

  ref <- do.call(rbind, lapply(split(dat$y, dat$x), iqr_fun, type = 2))
  ld2 <- build(2)
  expect_equal(sort(ld2$ymin), sort(ref$ymin), tolerance = 1e-10)
})

test_that("stat_error(fun.args = ...) wins over auto-routed ... on collision", {
  fn <- function(y, k = 1) {
    data.frame(y = mean(y), ymin = mean(y) - k, ymax = mean(y) + k)
  }
  dat <- data.frame(x = factor(rep("a", 5)), y = rnorm(5))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    stat_error(fun = fn, k = 1, fun.args = list(k = 99))
  ld <- ggplot2::ggplot_build(p)$data[[1]]
  expect_equal(ld$ymax - ld$y, 99, tolerance = 1e-10)
})

test_that("stat_error doesn't warn about geom-bound ... args", {
  iqr_fun <- function(y, type = 7) {
    data.frame(
      y    = median(y),
      ymin = stats::quantile(y, 0.25, type = type, names = FALSE),
      ymax = stats::quantile(y, 0.75, type = type, names = FALSE)
    )
  }
  dat <- data.frame(x = factor(rep("a", 10)), y = rnorm(10))
  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
    stat_error(fun = iqr_fun, type = 2, colour_neg = "red")
  expect_no_warning(ggplot2::ggplot_build(p))
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

# ---- default-value info messages ------------------------------------------

test_that("stat_error emits a classed info message when fun is defaulted", {
  expect_message(
    stat_error(),
    class = "ggerror_message_defaults"
  )
})

test_that("stat_error mentions conf.int when mean_ci uses the default", {
  expect_message(
    stat_error(fun = "mean_ci"),
    regexp  = "conf\\.int = 0\\.95",
    class   = "ggerror_message_defaults"
  )
})

test_that("stat_error stays silent when both fun and conf.int are explicit", {
  expect_no_message(stat_error(fun = "mean_ci", conf.int = 0.9))
})

# ---- size-1 group error ---------------------------------------------------

test_that("stat_error raises a classed error when any group has < 2 obs", {
  # mtcars$rn is unique per row, so every group has exactly 1 observation.
  dat <- data.frame(rn = rownames(mtcars), mpg = mtcars$mpg)
  p   <- ggplot2::ggplot(dat, ggplot2::aes(rn, mpg)) + stat_error()
  expect_error(
    ggplot2::ggplot_build(p),
    class = "ggerror_error_too_few_obs"
  )
})

test_that("stat_error accepts groups that all have >= 2 obs", {
  dat <- data.frame(
    cat = factor(rep(letters[1:3], each = 2)),
    val = c(1, 2, 3, 4, 5, 6)
  )
  p   <- ggplot2::ggplot(dat, ggplot2::aes(cat, val)) + stat_error()
  expect_no_error(ggplot2::ggplot_build(p))
})
