# validate_stat_fun_return(): enforces ggplot2's fun.data contract — a
# single-row data.frame with numeric columns `y`, `ymin`, `ymax` and
# ymin <= y <= ymax.

test_that("validate_stat_fun_return accepts a valid single-row data.frame", {
  ok <- data.frame(y = 1, ymin = 0, ymax = 2)
  expect_identical(ggerror:::validate_stat_fun_return(ok), ok)
})

test_that("validate_stat_fun_return rejects non-data.frame returns", {
  expect_error(
    ggerror:::validate_stat_fun_return(list(y = 1, ymin = 0, ymax = 2)),
    class = "ggerror_error_bad_fun_return"
  )
  expect_error(
    ggerror:::validate_stat_fun_return(c(y = 1, ymin = 0, ymax = 2)),
    class = "ggerror_error_bad_fun_return"
  )
})

test_that("validate_stat_fun_return rejects multi-row data.frames", {
  expect_error(
    ggerror:::validate_stat_fun_return(
      data.frame(y = 1:2, ymin = 0:1, ymax = 2:3)
    ),
    class = "ggerror_error_bad_fun_return"
  )
})

test_that("validate_stat_fun_return rejects missing columns", {
  expect_error(
    ggerror:::validate_stat_fun_return(data.frame(y = 1, ymin = 0)),
    class = "ggerror_error_bad_fun_return"
  )
})

test_that("validate_stat_fun_return rejects non-numeric columns", {
  expect_error(
    ggerror:::validate_stat_fun_return(
      data.frame(y = "a", ymin = "b", ymax = "c")
    ),
    class = "ggerror_error_bad_fun_return"
  )
})

test_that("validate_stat_fun_return rejects ymin > y or ymax < y", {
  expect_error(
    ggerror:::validate_stat_fun_return(data.frame(y = 1, ymin = 2, ymax = 3)),
    class = "ggerror_error_bad_fun_return"
  )
  expect_error(
    ggerror:::validate_stat_fun_return(data.frame(y = 5, ymin = 0, ymax = 2)),
    class = "ggerror_error_bad_fun_return"
  )
})
