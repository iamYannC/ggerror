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



test_that("geom_error_* wrappers pin their error_geom", {
  dat <- data.frame(x = 1:3, y = c("a", "b", "c"), e = c(0.1, 0.2, 0.3))

  for (type in c("linerange", "crossbar", "pointrange")) {
    wrapper <- get(paste0("geom_error_", type), envir = asNamespace("ggerror"))
    p <- ggplot2::ggplot(dat, ggplot2::aes(x, y)) +
      wrapper(ggplot2::aes(error = e))

    layer <- p$layers[[1]]
    expect_identical(layer$geom_params$error_geom, type)
  }
})

test_that("geom_error_* wrappers reject a conflicting error_geom", {
  expect_error(
    geom_error_linerange(error_geom = "crossbar"),
    class = "ggerror_error_pinned_error_geom"
  )
  expect_error(
    geom_error_crossbar(error_geom = "linerange"),
    class = "ggerror_error_pinned_error_geom"
  )
  expect_error(
    geom_error_pointrange(error_geom = "errorbar"),
    class = "ggerror_error_pinned_error_geom"
  )
})

test_that("invalid error_geom is rejected at the call site", {
  expect_error(
    geom_error(error_geom = "bogus"),
    class = "ggerror_error_bad_error_geom"
  )
})

test_that("invalid orientation is rejected at the call site", {
  expect_error(
    geom_error(orientation = "diagonal"),
    class = "ggerror_error_bad_orientation"
  )
  expect_error(
    geom_error(orientation = c("x", "y")),
    class = "ggerror_error_bad_orientation"
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

test_that("negative error values are rejected with a classed condition", {
  p <- ggplot2::ggplot(
    data.frame(x = 1:3, y = c("a", "b", "c"), e = c(0.1, -0.2, 0.3)),
    ggplot2::aes(x, y)
  ) +
    geom_error(ggplot2::aes(error = e))

  expect_error(
    ggplot2::ggplot_build(p),
    class = "ggerror_error_negative_error_aes"
  )
})

# --- dispatch contract tests ------------------------------------------------

# Regression guard for the draw_panel dispatch bug: when `error_geom` was
# silently stripped by Geom$draw_layer() (because draw_panel had `...` in
# its formals), every wrapper rendered identically to the default errorbar.
# This test catches that by asserting each error_geom produces a distinct SVG.
test_that("every error_geom produces a distinct rendered SVG", {
  skip_if_not_installed("svglite")

  dat <- mtcars
  dat$rn <- rownames(mtcars)

  render_svg <- function(error_geom) {
    p <- ggplot2::ggplot(dat, ggplot2::aes(mpg, rn)) +
      geom_error(ggplot2::aes(error = drat), error_geom = error_geom)
    path <- tempfile(fileext = ".svg")
    on.exit(unlink(path), add = TRUE)
    ggplot2::ggsave(path, p, device = svglite::svglite,
                    width = 6, height = 8)
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }

  svgs <- vapply(
    c("errorbar", "linerange", "crossbar", "pointrange"),
    render_svg,
    character(1)
  )

  expect_length(unique(svgs), 4L)
})

# Side-by-side visual doppelgangers: each error_geom must render the same as
# the corresponding base ggplot2 geom given equivalent xmin/xmax mapping.
test_that("geom_error_crossbar matches geom_crossbar visually", {
  skip_if_not_installed("vdiffr")
  dat <- mtcars; dat$rn <- rownames(mtcars)
  p <- ggplot2::ggplot(dat, ggplot2::aes(mpg, rn)) +
    geom_error_crossbar(ggplot2::aes(error = drat))
  ref <- ggplot2::ggplot(dat, ggplot2::aes(mpg, rn)) +
    ggplot2::geom_crossbar(ggplot2::aes(xmin = mpg - drat, xmax = mpg + drat))
  vdiffr::expect_doppelganger("match-crossbar-ours", p)
  vdiffr::expect_doppelganger("match-crossbar-ref",  ref)
})

test_that("geom_error_linerange matches geom_linerange visually", {
  skip_if_not_installed("vdiffr")
  dat <- mtcars; dat$rn <- rownames(mtcars)
  p <- ggplot2::ggplot(dat, ggplot2::aes(mpg, rn)) +
    geom_error_linerange(ggplot2::aes(error = drat))
  ref <- ggplot2::ggplot(dat, ggplot2::aes(mpg, rn)) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = mpg - drat, xmax = mpg + drat))
  vdiffr::expect_doppelganger("match-linerange-ours", p)
  vdiffr::expect_doppelganger("match-linerange-ref",  ref)
})

test_that("geom_error_pointrange matches geom_pointrange visually", {
  skip_if_not_installed("vdiffr")
  dat <- mtcars; dat$rn <- rownames(mtcars)
  p <- ggplot2::ggplot(dat, ggplot2::aes(mpg, rn)) +
    geom_error_pointrange(ggplot2::aes(error = drat))
  ref <- ggplot2::ggplot(dat, ggplot2::aes(mpg, rn)) +
    ggplot2::geom_pointrange(ggplot2::aes(xmin = mpg - drat, xmax = mpg + drat))
  vdiffr::expect_doppelganger("match-pointrange-ours", p)
  vdiffr::expect_doppelganger("match-pointrange-ref",  ref)
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
    geom_error(ggplot2::aes(error = drat), error_geom = "linerange")

  vdiffr::expect_doppelganger("linerange-discrete-y", p)
})

test_that("geom_error renders crossbar variant", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, rownames(mtcars))) +
    geom_error(ggplot2::aes(error = drat), error_geom = "crossbar")

  vdiffr::expect_doppelganger("crossbar-discrete-y", p)
})

test_that("geom_error renders pointrange variant", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, rownames(mtcars))) +
    geom_error(ggplot2::aes(error = drat), error_geom = "pointrange")

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
