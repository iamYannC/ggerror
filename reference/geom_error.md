# Error bars with automatic orientation

A thin wrapper around
[`ggplot2::geom_errorbar()`](https://ggplot2.tidyverse.org/reference/geom_linerange.html),
[`ggplot2::geom_linerange()`](https://ggplot2.tidyverse.org/reference/geom_linerange.html),
[`ggplot2::geom_crossbar()`](https://ggplot2.tidyverse.org/reference/geom_linerange.html),
and
[`ggplot2::geom_pointrange()`](https://ggplot2.tidyverse.org/reference/geom_linerange.html)
that accepts a single `error` aesthetic and figures out orientation from
the data. For asymmetric errors, use `error_neg` + `error_pos` instead
of `error`.

## Usage

``` r
geom_error(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  ...,
  error_geom = "errorbar",
  orientation = NA,
  sign_aware = FALSE,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)

geom_error_linerange(..., error_geom)

geom_error_crossbar(..., error_geom)

geom_error_pointrange(..., error_geom)
```

## Arguments

- mapping:

  Set of aesthetic mappings created by
  [`ggplot2::aes()`](https://ggplot2.tidyverse.org/reference/aes.html).

- data:

  The data to be displayed in this layer.

- stat:

  The statistical transformation to use on the data. Defaults to
  `"identity"`.

- position:

  Position adjustment.

- ...:

  Other arguments passed on to
  [`ggplot2::layer()`](https://ggplot2.tidyverse.org/reference/layer.html).

- error_geom:

  One of `"errorbar"` (default), `"linerange"`, `"crossbar"`, or
  `"pointrange"`. Chooses which ggplot2 error geom `geom_error()`
  dispatches to under the hood.

- orientation:

  Either `NA` (the default; inferred from the data), `"x"` (vertical
  error), or `"y"` (horizontal error).

- sign_aware:

  If `TRUE`, signed values in `error` are routed per row: positive
  values extend the bar in the positive direction, negative values
  extend it in the negative direction, and the opposite side is
  suppressed. Useful for residual plots where `x`/`y` is the fitted
  value and the bar extends toward the observed value. Incompatible with
  `stat = "error"`. Default `FALSE`.

- na.rm:

  If `FALSE`, missing values are removed with a warning.

- show.legend:

  Logical. Should this layer be included in the legends?

- inherit.aes:

  If `FALSE`, overrides the default aesthetics.

## Package options

Session-level knobs for the `0 -> NA` migration. Set via
[`options()`](https://rdrr.io/r/base/options.html):

- `ggerror.silent_zero_warning` — `TRUE` suppresses the soft deprecation
  fired when `error_neg` or `error_pos` is set to `0` (You are
  encouraged to set it to `NA`). Default `FALSE`.

- `ggerror.zero_threshold` — Numeric absolute tolerance for zero-value
  detection. Values with a magnitude below this threshold are treated as
  exactly zero, triggering the warning. Defaults to `1e-8`.

## Aesthetics

`geom_error()` requires `x`, `y`, and one of:

- `error` — symmetric half-width applied along the non-categorical axis.

- `error_neg` **and** `error_pos` — asymmetric; the bar extends
  `error_neg` in the negative direction and `error_pos` in the positive
  direction along the non-categorical axis. For a one-sided bar, set the
  unused side to `NA` — the cap, stem, and shared-bound cap on that side
  are all suppressed.

Mixing `error` with `error_neg` / `error_pos` is an error, as is
providing only one of the asymmetric pair.

Fixed per-side styling can be supplied through `...` with `_neg` and
`_pos` suffixes for `colour`, `fill`, `linewidth`, `linetype`, `alpha`,
and `width`. These are fixed scalar parameters, not mapped aesthetics.

## Examples

``` r
library(ggplot2)

ggplot(mtcars, aes(mpg, rownames(mtcars))) +
  geom_point() +
  geom_error(aes(error = drat))


ggplot(mtcars, aes(factor(cyl), mpg)) +
  geom_point() +
  geom_error(aes(error = drat), error_geom = "pointrange")


# Asymmetric: bar extends drat/2 below and drat above each point
ggplot(mtcars, aes(mpg, rownames(mtcars))) +
  geom_point() +
  geom_error(aes(error_neg = drat / 2, error_pos = drat))


# One-sided: set the unused side to NA (cap + stem auto-suppressed)
ggplot(mtcars, aes(mpg, rownames(mtcars))) +
  geom_point() +
  geom_error(aes(error_neg = NA, error_pos = drat))


# Summarise raw data: mean +/- SE per group (see also stat_error())
ggplot(mtcars, aes(factor(cyl), mpg)) +
  geom_error(stat = "error", error_geom = "pointrange")


# Signed residual plot: bar extends from fitted toward observed
model <- lm(mpg ~ wt, data = mtcars)
ggplot(mtcars, aes(fitted(model), mpg)) +
  geom_point() +
  geom_error(aes(error = resid(model)),
             sign_aware = TRUE, orientation = "x")


# Style the negative and positive halves separately
ggplot(mtcars, aes(mpg, rownames(mtcars))) +
  geom_point() +
  geom_error(
    aes(error_neg = drat / 2, error_pos = drat),
    colour_neg = "steelblue",
    colour_pos = "firebrick"
  )

```
