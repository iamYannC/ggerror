# split_dots_for_fun(): routes `...` names matching `fn`'s formals to
# `fun.args`; the rest flow on to the geom. When `fn` accepts `...`, any
# name that isn't a known geom/aesthetic param also routes to `fun`.

test_that("empty dots produce empty splits", {
  out <- ggerror:::split_dots_for_fun(list(), function(y) y)
  expect_length(out$to_fun, 0L)
  expect_identical(out$to_geom, list())
})

test_that("names matching fn formals route to fun", {
  fn  <- function(y, type = 7) y
  out <- ggerror:::split_dots_for_fun(list(type = 2, colour_neg = "red"), fn)
  expect_identical(out$to_fun,  list(type = 2))
  expect_identical(out$to_geom, list(colour_neg = "red"))
})

test_that("known geom/aesthetic names stay with geom even if fn has ...", {
  fn  <- function(y, ...) y
  out <- ggerror:::split_dots_for_fun(
    list(colour_neg = "red", colour = "blue", linewidth = 1.2, width = 0.5),
    fn
  )
  expect_length(out$to_fun, 0L)
  expect_named(out$to_geom,
               c("colour_neg", "colour", "linewidth", "width"))
})

test_that("unknown names route to fun when fn accepts dots", {
  fn  <- function(y, ...) y
  out <- ggerror:::split_dots_for_fun(list(foo = 1, colour_neg = "red"), fn)
  expect_identical(out$to_fun,  list(foo = 1))
  expect_identical(out$to_geom, list(colour_neg = "red"))
})

test_that("unknown names stay with geom when fn lacks dots", {
  fn  <- function(y, type = 7) y
  out <- ggerror:::split_dots_for_fun(list(foo = 1), fn)
  expect_length(out$to_fun, 0L)
  expect_identical(out$to_geom, list(foo = 1))
})

test_that("unnamed dots bail out to geom", {
  fn  <- function(y, type = 7) y
  out <- ggerror:::split_dots_for_fun(list(2), fn)
  expect_identical(out$to_fun,  list())
  expect_length(out$to_geom, 1L)
})
