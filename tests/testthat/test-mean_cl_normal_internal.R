# mean_cl_normal_internal(): base-R normal-theory CI. No Hmisc dep.
# Returns a single-row data.frame with `y`, `ymin`, `ymax`. `conf.int`
# controls the level; `na.rm` drops NAs before summarising.

test_that("mean_cl_normal_internal returns the fun.data shape", {
  out <- ggerror:::mean_cl_normal_internal(1:10)
  expect_s3_class(out, "data.frame")
  expect_identical(nrow(out), 1L)
  expect_identical(names(out), c("y", "ymin", "ymax"))
})

test_that("mean_cl_normal_internal centres on the sample mean", {
  y <- c(1, 2, 3, 4, 5)
  out <- ggerror:::mean_cl_normal_internal(y)
  expect_equal(out$y, mean(y))
})

test_that("mean_cl_normal_internal default CI matches a manual computation", {
  set.seed(42)
  y  <- rnorm(20, mean = 5, sd = 2)
  out <- ggerror:::mean_cl_normal_internal(y)

  n  <- length(y)
  m  <- mean(y)
  se <- stats::sd(y) / sqrt(n)
  tq <- stats::qt(0.975, df = n - 1)
  expect_equal(out$ymin, m - tq * se)
  expect_equal(out$ymax, m + tq * se)
})

test_that("mean_cl_normal_internal widens with higher conf.int", {
  y <- c(1, 2, 3, 4, 5, 6)
  narrow <- ggerror:::mean_cl_normal_internal(y, conf.int = 0.80)
  wide   <- ggerror:::mean_cl_normal_internal(y, conf.int = 0.99)
  expect_gt(wide$ymax - wide$ymin, narrow$ymax - narrow$ymin)
})

test_that("mean_cl_normal_internal drops NAs when na.rm = TRUE", {
  y <- c(1, 2, NA, 4, 5)
  expect_equal(
    ggerror:::mean_cl_normal_internal(y, na.rm = TRUE)$y,
    mean(c(1, 2, 4, 5))
  )
})
