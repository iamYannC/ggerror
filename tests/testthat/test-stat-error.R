# stat_error() — raw-data summarising layer.
#
# Contract:
#  * stat_error() accepts x + y only; no error aesthetic is needed.
#  * `fun` defaults to "mean_se"; "mean_ci" maps to ggplot2::mean_cl_normal.
#  * A user-supplied function follows ggplot2's fun.data contract: it takes
#    a numeric vector and returns a single-row data.frame with `y`, `ymin`,
#    `ymax`.
#  * Built plot data carries ymin/ymax computed from `fun`, one row per
#    unique x (or y, when the orientation is horizontal).
#  * geom_error(stat = "error") is equivalent to stat_error().
#  * Composes with all four error_geom values.

# ---- default fun -----------------------------------------------------------

test_that("stat_error(fun = 'mean_se') produces mean/SE per group", {
  set.seed(1)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 10)),
    y = c(rnorm(10, 1), rnorm(10, 2), rnorm(10, 3))
  )

  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error()
  built <- ggplot2::ggplot_build(p)
  ld <- built$data[[1]]

  # one row per group
  expect_identical(nrow(ld), 3L)

  # compare to reference mean_se on each group's raw y
  ref <- do.call(rbind, lapply(split(dat$y, dat$x), ggplot2::mean_se))
  expect_equal(sort(ld$y),    sort(ref$y),    tolerance = 1e-10)
  expect_equal(sort(ld$ymin), sort(ref$ymin), tolerance = 1e-10)
  expect_equal(sort(ld$ymax), sort(ref$ymax), tolerance = 1e-10)
})

test_that("stat_error(fun = 'mean_ci') uses mean_cl_normal", {
  set.seed(2)
  dat <- data.frame(
    x = factor(rep(letters[1:3], each = 20)),
    y = rnorm(60)
  )

  p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) + stat_error(fun = "mean_ci")
  built <- ggplot2::ggplot_build(p)
  ld <- built$data[[1]]

  ref_fn <- ggerror:::mean_cl_normal_internal
  ref <- do.call(rbind, lapply(split(dat$y, dat$x), ref_fn))
  expect_equal(sort(ld$y),    sort(ref$y),    tolerance = 1e-10)
  expect_equal(sort(ld$ymin), sort(ref$ymin), tolerance = 1e-10)
  expect_equal(sort(ld$ymax), sort(ref$ymax), tolerance = 1e-10)
})

# ---- custom function -------------------------------------------------------

test_that("stat_error accepts a custom fun.data-style function", {
  my_fn <- function(y) {
    data.frame(
      y = median(y),
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
  built <- ggplot2::ggplot_build(p)
  ld <- built$data[[1]]

  ref <- do.call(rbind, lapply(split(dat$y, dat$x), my_fn))
  expect_equal(sort(ld$y),    sort(ref$y),    tolerance = 1e-10)
  expect_equal(sort(ld$ymin), sort(ref$ymin), tolerance = 1e-10)
  expect_equal(sort(ld$ymax), sort(ref$ymax), tolerance = 1e-10)
})

test_that("stat_error errors on unknown string fun", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) +
    stat_error(fun = "bogus")
  expect_error(
    ggplot2::ggplot_build(p),
    class = "ggerror_error_bad_fun"
  )
})

test_that("stat_error errors when custom fun returns the wrong shape", {
  bad_fn <- function(y) list(mean = mean(y))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) +
    stat_error(fun = bad_fn)
  expect_error(
    ggplot2::ggplot_build(p),
    class = "ggerror_error_bad_fun_return"
  )
})

# ---- dual entry points -----------------------------------------------------

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
  # bounds along y (the numeric axis)
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
  # bounds along x (the numeric axis)
  expect_true(all(c("xmin", "xmax") %in% names(ld)))
})
