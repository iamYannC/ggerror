# ggerror 0.4.0

* Added a pkgdown site at <https://iamyannc.github.io/ggerror/>.

# ggerror 0.3.0

* `ggerror` now includes a complete aestetic support for one sided error bars.
* Added fixed per-side styling parameters for error bars: `colour_neg` /
  `colour_pos`, `fill_neg` / `fill_pos`, `linewidth_neg` / `linewidth_pos`,
  `linetype_neg` / `linetype_pos`, `alpha_neg` / `alpha_pos`, and
  `width_neg` / `width_pos`.
* Fixed bug from 0.2.0: When supplying one-sided error bars, the unused side's width can be  set to `0`, default, for example
  `geom_error(aes(error_neg = 0, error_pos = se), width_neg = 0)`.
* Added a `vignette("ggerror")` covering symmetric, asymmetric, one-sided,
  and per-side styling workflows.

# ggerror 0.2.0

* New `error_neg` / `error_pos` aesthetics for **asymmetric** error bars. The
  bar extends `error_neg` in the negative direction and `error_pos` in the
  positive direction along the non-categorical axis.
* One-sided bars are supported by setting the unused side to `0` explicitly
  (e.g. `aes(error_neg = 0, error_pos = se)` for an upward-only bar).
* The existing symmetric `error` aesthetic is unchanged. Combining `error`
  with either `error_neg` / `error_pos`, or providing only one of the
  asymmetric pair, raises an error.

# ggerror 0.1.0

* Initial release. Provides `geom_error()` (plus `geom_error_linerange()`,
  `geom_error_crossbar()`, `geom_error_pointrange()`) wrapping ggplot2's
  error geoms behind a single `error` aesthetic with automatic orientation
  inference.
