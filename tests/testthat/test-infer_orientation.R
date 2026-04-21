test_that("infer_orientation returns 'y' when y is discrete", {
  d <- data.frame(x = 1:3, y = c("a", "b", "c"))
  expect_identical(infer_orientation(d, params = list()), "y")
})

test_that("infer_orientation returns 'x' when x is discrete", {
  d <- data.frame(x = c("a", "b", "c"), y = 1:3)
  expect_identical(infer_orientation(d, params = list()), "x")
})

test_that("infer_orientation defaults to 'y' when both axes numeric", {
  d <- data.frame(x = 1:3, y = 4:6)
  expect_message(
    out <- infer_orientation(d, params = list()),
    regexp = "orientation"
  )
  expect_identical(out, "y")
})

test_that("infer_orientation honours explicit orientation param", {
  d <- data.frame(x = 1:3, y = c("a", "b", "c"))
  expect_identical(
    infer_orientation(d, params = list(orientation = "x")),
    "x"
  )
  expect_identical(
    infer_orientation(d, params = list(orientation = "y")),
    "y"
  )
})

test_that("infer_orientation treats factors as discrete", {
  d <- data.frame(x = 1:3, y = factor(c("a", "b", "c")))
  expect_identical(infer_orientation(d, params = list()), "y")
})
