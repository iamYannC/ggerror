test_that("geom_error computes xmin/xmax when y is discrete", {
  p <- ggplot2::ggplot(
    data.frame(x = c(1, 2, 3), y = c("a", "b", "c"), e = c(0.1, 0.2, 0.3)),
    ggplot2::aes(x, y)
  ) +
    geom_error(ggplot2::aes(error = e))

  built <- ggplot2::ggplot_build(p)
  ld <- built$data[[1]]

  expect_true(all(c("xmin", "xmax") %in% names(ld)))
  expect_identical(ld$xmin, ld$x - c(0.1, 0.2, 0.3))
  expect_identical(ld$xmax, ld$x + c(0.1, 0.2, 0.3))
})

test_that("geom_error computes ymin/ymax when x is discrete", {
  p <- ggplot2::ggplot(
    data.frame(x = c("a", "b", "c"), y = c(1, 2, 3), e = c(0.1, 0.2, 0.3)),
    ggplot2::aes(x, y)
  ) +
    geom_error(ggplot2::aes(error = e))

  built <- ggplot2::ggplot_build(p)
  ld <- built$data[[1]]

  expect_true(all(c("ymin", "ymax") %in% names(ld)))
  expect_identical(ld$ymin, ld$y - c(0.1, 0.2, 0.3))
  expect_identical(ld$ymax, ld$y + c(0.1, 0.2, 0.3))
})

test_that("geom_error drops the custom 'error' column before drawing", {
  p <- ggplot2::ggplot(
    data.frame(x = c(1, 2), y = c("a", "b"), e = c(0.1, 0.2)),
    ggplot2::aes(x, y)
  ) +
    geom_error(ggplot2::aes(error = e))

  built <- ggplot2::ggplot_build(p)
  ld <- built$data[[1]]
  expect_false("error" %in% names(ld))
})

test_that("geom_err is an alias of geom_error", {
  expect_identical(geom_err, geom_error)
})

test_that("geom_error_* wrappers pin their err_type", {
  dat <- data.frame(x = 1:3, y = c("a", "b", "c"), e = c(0.1, 0.2, 0.3))

  for (type in c("linerange", "crossbar", "pointrange")) {
    wrapper <- get(paste0("geom_error_", type), envir = asNamespace("ggerror"))
    p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
      wrapper(ggplot2::aes(error = e))

    layer <- p$layers[[1]]
    expect_identical(layer$geom_params$err_type, type)
  }
})

test_that("geom_error_* wrappers reject a conflicting err_type", {
  expect_error(
    geom_error_linerange(err_type = "crossbar"),
    regexp = "err_type"
  )
})

test_that("invalid err_type is rejected with a clear error", {
  expect_error(
    {
      p <- ggplot2::ggplot(
        data.frame(x = 1:3, y = c("a", "b", "c"), e = c(0.1, 0.2, 0.3)),
        ggplot2::aes(x, y)
      ) +
        geom_error(ggplot2::aes(error = e), err_type = "bogus")
      ggplot2::ggplot_build(p)
    },
    regexp = "err_type"
  )
})

test_that("geom_error errors when 'error' aesthetic is missing", {
  expect_error(
    {
      p <- ggplot2::ggplot(
        data.frame(x = 1:3, y = c("a", "b", "c")),
        ggplot2::aes(x, y)
      ) +
        geom_error()
      ggplot2::ggplot_build(p)
    },
    regexp = "error"
  )
})

# --- vdiffr snapshot tests --------------------------------------------------

test_that("geom_error renders symmetric errorbar on discrete y", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, rownames(mtcars))) +
    ggplot2::geom_point() +
    geom_error(ggplot2::aes(error = drat))

  vdiffr::expect_doppelganger("symmetric-errorbar-discrete-y", p)
})

test_that("geom_error renders linerange variant", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, rownames(mtcars))) +
    ggplot2::geom_point() +
    geom_error(ggplot2::aes(error = drat), err_type = "linerange")

  vdiffr::expect_doppelganger("linerange-discrete-y", p)
})

test_that("geom_error renders crossbar variant", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, rownames(mtcars))) +
    geom_error(ggplot2::aes(error = drat), err_type = "crossbar")

  vdiffr::expect_doppelganger("crossbar-discrete-y", p)
})

test_that("geom_error renders pointrange variant", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, rownames(mtcars))) +
    geom_error(ggplot2::aes(error = drat), err_type = "pointrange")

  vdiffr::expect_doppelganger("pointrange-discrete-y", p)
})

test_that("geom_error renders with two numeric axes (default orientation y)", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point() +
    suppressMessages(geom_error(ggplot2::aes(error = drat)))

  vdiffr::expect_doppelganger("symmetric-errorbar-two-numeric", p)
})

test_that("geom_error renders on discrete x (vertical error bars)", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) +
    ggplot2::geom_point() +
    geom_error(ggplot2::aes(error = drat))

  vdiffr::expect_doppelganger("symmetric-errorbar-discrete-x", p)
})
