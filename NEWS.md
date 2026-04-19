# ggerror 0.3.0

* Added fixed per-side styling parameters for error bars: `colour_neg` /
  `colour_pos`, `fill_neg` / `fill_pos`, `linewidth_neg` / `linewidth_pos`,
  `linetype_neg` / `linetype_pos`, `alpha_neg` / `alpha_pos`, and
  `width_neg` / `width_pos`.
* One-sided error bars can now suppress the shared-bound cap by setting the
  unused side's width to `0`, for example
  `geom_error(aes(error_neg = 0, error_pos = se), width_neg = 0)`.
* Added a `vignette("ggerror")` covering symmetric, asymmetric, one-sided,
  and per-side styling workflows.
* Internal: preserved the existing fast path when no per-side overrides are
  supplied, and refactored split rendering so the shared midpoint is not
  drawn as an extra cap for `errorbar`.

# ggerror 0.2.0

* New `error_neg` / `error_pos` aesthetics for **asymmetric** error bars. The
  bar extends `error_neg` in the negative direction and `error_pos` in the
  positive direction along the non-categorical axis.
* One-sided bars are supported by setting the unused side to `0` explicitly
  (e.g. `aes(error_neg = 0, error_pos = se)` for an upward-only bar).
* The existing symmetric `error` aesthetic is unchanged. Combining `error`
  with either `error_neg` / `error_pos`, or providing only one of the
  asymmetric pair, raises a classed error.

# ggerror 0.1.0

* Initial release. Provides `geom_error()` (plus `geom_error_linerange()`,
  `geom_error_crossbar()`, `geom_error_pointrange()`) wrapping ggplot2's
  error geoms behind a single `error` aesthetic with automatic orientation
  inference.
