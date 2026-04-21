# call_stat_fun(): forwards `conf.int` to `fn` only when `fn` declares it
# (or absorbs `...`). Lets us expose `conf.int` at the stat_error() level
# without breaking funs that don't accept it (e.g. ggplot2::mean_se).

test_that("call_stat_fun forwards conf.int when fn declares it", {
  fn <- function(y, conf.int = 0.95) {
    data.frame(y = mean(y), ymin = conf.int, ymax = conf.int)
  }
  out <- ggerror:::call_stat_fun(fn, 1:10, conf.int = 0.9)
  expect_equal(out$ymin, 0.9)
  expect_equal(out$ymax, 0.9)
})

test_that("call_stat_fun forwards conf.int when fn has ...", {
  fn <- function(y, ...) {
    dots <- list(...)
    data.frame(y = mean(y), ymin = dots$conf.int, ymax = dots$conf.int)
  }
  out <- ggerror:::call_stat_fun(fn, 1:5, conf.int = 0.8)
  expect_equal(out$ymin, 0.8)
})

test_that("call_stat_fun drops conf.int when fn doesn't accept it", {
  fn <- function(y, mult = 1) {
    data.frame(y = mean(y), ymin = mean(y) - mult, ymax = mean(y) + mult)
  }
  expect_no_error(ggerror:::call_stat_fun(fn, 1:5, conf.int = 0.9))
})

test_that("call_stat_fun works with ggplot2::mean_se (no conf.int formal)", {
  out <- ggerror:::call_stat_fun(ggplot2::mean_se, c(1, 2, 3, 4, 5),
                                 conf.int = 0.95)
  expect_s3_class(out, "data.frame")
  expect_identical(nrow(out), 1L)
})

test_that("call_stat_fun works with mean_cl_normal_internal", {
  out <- ggerror:::call_stat_fun(ggerror:::mean_cl_normal_internal,
                                 c(1, 2, 3, 4, 5), conf.int = 0.9)
  ref <- ggerror:::mean_cl_normal_internal(c(1, 2, 3, 4, 5), conf.int = 0.9)
  expect_equal(out, ref)
})
