# Changelog

## ggerror 1.0.0

- New
  [`stat_error()`](https://iamyannc.github.io/ggerror/reference/stat_error.md)
  summarises raw observation-level data into error bounds. Accepts
  `fun = "mean_se"` (default), `"mean_ci"` (95% normal- theory CI, no
  Hmisc dep), or a custom function following ggplot2’s `fun.data`
  contract. Also available via `geom_error(stat = "error")`.
- New `sign_aware = TRUE` routes signed per-row values (typically
  residuals) into one-sided bars whose direction encodes the sign.
  Enables one-layer [`lm()`](https://rdrr.io/r/stats/lm.html) residual
  plots.
- `aes(error_neg = NA, error_pos = ...)` is now the canonical idiom for
  one-sided bars — the cap and stem on the NA side auto-suppress.
  Passing `0` still renders but emits a soft deprecation warning;
  silence with `options(ggerror.silent_zero_warning = TRUE)` or tune the
  detection threshold via `options(ggerror.zero_threshold = ...)`.
- New diagnostics: NA values in symmetric `error` now warn with row
  indices (class `ggerror_warn_error_na`); negative values without
  `sign_aware` abort with row indices and a migration suggestion (class
  `ggerror_error_negative_error_aes`).
- New vignette `lm-residuals` covering
  [`stat_error()`](https://iamyannc.github.io/ggerror/reference/stat_error.md)
  and `sign_aware` with an [`lm()`](https://rdrr.io/r/stats/lm.html)
  residual-plot demo.

## ggerror 0.4.0

- Added a pkgdown site at <https://iamyannc.github.io/ggerror/>.

## ggerror 0.3.0

CRAN release: 2026-04-21

- `ggerror` now includes a complete aestetic support for one sided error
  bars.
- Added fixed per-side styling parameters for error bars: `colour_neg` /
  `colour_pos`, `fill_neg` / `fill_pos`, `linewidth_neg` /
  `linewidth_pos`, `linetype_neg` / `linetype_pos`, `alpha_neg` /
  `alpha_pos`, and `width_neg` / `width_pos`.
- Fixed bug from 0.2.0: When supplying one-sided error bars, the unused
  side’s width can be set to `0`, default, for example
  `geom_error(aes(error_neg = 0, error_pos = se), width_neg = 0)`.
- Added a
  [`vignette("ggerror")`](https://iamyannc.github.io/ggerror/articles/ggerror.md)
  covering symmetric, asymmetric, one-sided, and per-side styling
  workflows.

## ggerror 0.2.0

- New `error_neg` / `error_pos` aesthetics for **asymmetric** error
  bars. The bar extends `error_neg` in the negative direction and
  `error_pos` in the positive direction along the non-categorical axis.
- One-sided bars are supported by setting the unused side to `0`
  explicitly (e.g. `aes(error_neg = 0, error_pos = se)` for an
  upward-only bar).
- The existing symmetric `error` aesthetic is unchanged. Combining
  `error` with either `error_neg` / `error_pos`, or providing only one
  of the asymmetric pair, raises an error.

## ggerror 0.1.0

- Initial release. Provides
  [`geom_error()`](https://iamyannc.github.io/ggerror/reference/geom_error.md)
  (plus
  [`geom_error_linerange()`](https://iamyannc.github.io/ggerror/reference/geom_error.md),
  [`geom_error_crossbar()`](https://iamyannc.github.io/ggerror/reference/geom_error.md),
  [`geom_error_pointrange()`](https://iamyannc.github.io/ggerror/reference/geom_error.md))
  wrapping ggplot2’s error geoms behind a single `error` aesthetic with
  automatic orientation inference.
