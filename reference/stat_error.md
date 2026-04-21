# Summarising stat for `geom_error()`

`stat_error()` computes the error bounds from raw observation-level data
using ggplot2's `fun.data` contract. Where
[`geom_error()`](https://iamyannc.github.io/ggerror/reference/geom_error.md)
expects pre- computed error columns, `stat_error()` summarises `y` (or
`x`, when orientation is horizontal) within each group via the function
supplied to `fun`.

## Usage

``` r
stat_error(
  mapping = NULL,
  data = NULL,
  geom = NULL,
  position = "identity",
  ...,
  fun = "mean_se",
  fun.args = list(),
  error_geom = "errorbar",
  orientation = NA,
  na.rm = FALSE,
  conf.int = 0.95,
  show.legend = NA,
  inherit.aes = TRUE
)
```

## Arguments

- mapping, data, position, show.legend, inherit.aes:

  Standard ggplot2 layer arguments.

- geom:

  The geom to render the summary with. Defaults to GeomErrorStat, which
  reuses
  [`geom_error()`](https://iamyannc.github.io/ggerror/reference/geom_error.md)'s
  draw path.

- ...:

  Additional parameters. Names that match `fun`'s formals (or any name,
  when `fun` accepts `...`) are forwarded to `fun`; the remainder go to
  [`geom_error()`](https://iamyannc.github.io/ggerror/reference/geom_error.md)
  as per-side styling (`colour_neg`, `width_pos`, …) or standard
  aesthetics.

- fun:

  One of `"mean_se"` (default, uses
  [`ggplot2::mean_se()`](https://ggplot2.tidyverse.org/reference/mean_se.html)),
  `"mean_ci"` (mean with 95% normal-theory CI via
  [`stats::qt()`](https://rdrr.io/r/stats/TDist.html); no Hmisc
  dependency), or a function taking a numeric vector and returning a
  single-row data.frame with columns `y`, `ymin`, `ymax`.

- fun.args:

  Named list of extra arguments to pass to `fun`. Merged with any `...`
  arguments whose names match `fun`'s formals; `fun.args` wins on
  collision.

- error_geom:

  One of `"errorbar"` (default), `"linerange"`, `"crossbar"`,
  `"pointrange"`.

- orientation:

  `NA` (default, inferred), `"x"`, or `"y"`.

- na.rm:

  If `TRUE`, drop `NA` values from the summarised axis before applying
  `fun`.

- conf.int:

  Confidence level forwarded to `fun` when the function accepts a
  `conf.int` argument (e.g. `fun = "mean_ci"` or a custom `fun.data`
  with that formal). Ignored for funs that don't declare it, so it's
  safe to leave at the default when using `fun = "mean_se"`.

## Examples

``` r
library(ggplot2)

ggplot(mtcars, aes(factor(cyl), mpg)) + stat_error()
#> `stat_error()` using fun = "mean_se".


ggplot(mtcars, aes(factor(cyl), mpg)) +
  stat_error(fun = "mean_ci", error_geom = "pointrange")
#> `stat_error()` using fun = "mean_ci" and conf.int = 0.95.


# 90% CI with NA-tolerant summarising:
ggplot(mtcars, aes(factor(cyl), mpg)) +
  stat_error(fun = "mean_ci", conf.int = 0.9, na.rm = TRUE)

```
