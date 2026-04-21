# resolve_stat_fun(): maps `fun` strings to their implementations and
# accepts functions as-is. Unknown / non-character-non-function values
# raise a classed error.

test_that("resolve_stat_fun maps 'mean_se' to ggplot2::mean_se", {
  expect_identical(ggerror:::resolve_stat_fun("mean_se"), ggplot2::mean_se)
})

test_that("resolve_stat_fun maps 'mean_ci' to the internal CI helper", {
  expect_identical(
    ggerror:::resolve_stat_fun("mean_ci"),
    ggerror:::mean_cl_normal_internal
  )
})

test_that("resolve_stat_fun returns a function argument unchanged", {
  my_fn <- function(y) data.frame(y = mean(y), ymin = min(y), ymax = max(y))
  expect_identical(ggerror:::resolve_stat_fun(my_fn), my_fn)
})

test_that("resolve_stat_fun errors on unknown strings", {
  expect_error(
    ggerror:::resolve_stat_fun("bogus"),
    class = "ggerror_error_bad_fun"
  )
})

test_that("resolve_stat_fun errors on non-string, non-function inputs", {
  expect_error(
    ggerror:::resolve_stat_fun(42),
    class = "ggerror_error_bad_fun"
  )
  expect_error(
    ggerror:::resolve_stat_fun(c("mean_se", "mean_ci")),
    class = "ggerror_error_bad_fun"
  )
})
