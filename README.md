# ggerror <img src="man/figures/logo.png" alt="ggerror hex logo" align="right" height="150"/>

[![CRAN status](https://www.r-pkg.org/badges/version/ggerror)](https://CRAN.R-project.org/package=ggerror)
[![R-CMD-check](https://github.com/iamYannC/ggerror/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/iamYannC/ggerror/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/iamYannC/ggerror/graph/badge.svg)](https://app.codecov.io/gh/iamYannC/ggerror)


`ggerror` collapses **ggplot2**'s family of error geoms into one
error-focused API. Pass `error` (or `error_neg` + `error_pos`) and
`ggerror` figures out orientation, picks the right base geom, and lets
you style each side independently. It also computes errors directly
from raw data with `stat_error()`, and renders signed quantities (like
residuals) as direction-aware bars in a single layer.

### Installation

``` r
install.packages("ggerror")          # CRAN
pak::pak("iamyannc/ggerror")         # development version
```

### Quickstart

The examples below use the built-in `CO2` dataset — CO₂ uptake by
*Echinochloa crus-galli* plants from Quebec and Mississippi, chilled
overnight or not.

``` r
library(ggplot2)
library(ggerror)

set_theme(theme_minimal(base_size = 13))

co2_sum <- aggregate(uptake ~ Type + Treatment, data = CO2,
                     FUN = function(x) c(m = mean(x), s = sd(x), v = var(x)))
co2_sum <- do.call(data.frame, co2_sum)
```

#### Symmetric errors — pinned wrapper

``` r
ggplot(co2_sum, aes(Type, uptake.m, colour = Treatment)) +
  geom_point(size = 3) +
  geom_error_pointrange(aes(error = uptake.s),
                        position = position_dodge(0.4))
```

#### Asymmetric + per-side styling — `error_geom` argument form

``` r
ggplot(co2_sum, aes(Type, uptake.m)) +
  geom_error(aes(error_neg = uptake.s, error_pos = sqrt(uptake.v)),
             error_geom = "crossbar",
             colour_neg = "steelblue", colour_pos = "firebrick",
             width_neg = 0.3, width_pos = 0.6) +
  facet_wrap(~ Treatment)
```

#### Summarise raw data with `stat_error()`

``` r
ggplot(CO2, aes(Treatment, uptake)) +
  stat_error(fun = "mean_ci", error_geom = "pointrange")
```

→ see `vignette("use-cases")` for the full walkthrough, including
custom summary functions.

#### Residuals in one layer with `sign_aware`

``` r
model <- lm(uptake ~ conc, data = CO2)
co2_fit <- transform(CO2,
                     predicted = predict(model),
                     residual  = resid(model))

ggplot(co2_fit, aes(conc, predicted)) +
  geom_line() +
  geom_point(aes(y = uptake), alpha = 0.4) +
  geom_error(aes(error = residual),
             sign_aware = TRUE, orientation = "x",
             colour_pos = "firebrick", colour_neg = "steelblue")
```

→ see `vignette("use-cases")` for the residual-diagnostics walkthrough.

### Supported geoms

| ggplot2 Base      | `geom_error(error_geom = ...)` | Specific Wrapper          |
|:------------------|:-------------------------------|:--------------------------|
| `geom_errorbar`   | `"errorbar"` (default)         | `geom_error()`            |
| `geom_linerange`  | `"linerange"`                  | `geom_error_linerange()`  |
| `geom_pointrange` | `"pointrange"`                 | `geom_error_pointrange()` |
| `geom_crossbar`   | `"crossbar"`                   | `geom_error_crossbar()`   |

Both the pinned wrapper (`geom_error_pointrange()`) and the argument
form (`geom_error(error_geom = "pointrange")`) produce the same layer —
pick whichever reads better at the call site. The argument form
composes well with functional patterns like
`purrr::map(geoms, ~ geom_error(error_geom = .x, ...))`.

### Learn more

- `vignette("ggerror")` — the geom API tutorial: simple, asymmetric,
  one-sided.
- `vignette("use-cases")` — `stat_error()` summaries and `sign_aware`
  residuals on a real model.

### Disclaimer

This package was developed with the assistance of AI tools. All code has been reviewed by the author, who remains responsible for its quality. Ideas for new geoms are welcome.

<!-- ============= NOTE ============
Review against `dev/new-vignettes.txt`:

- The README is already clearer than the old API-heavy version, but it still
  opens abstractly. If the goal is "show features, not crap", I would front-load
  one hero plot plus 3 short bullets (`simple defaults`, `asymmetric / one-sided`,
  `stats + sign-aware`) before installation.

- The asymmetric example is structurally correct but rhetorically weak:
  `sqrt(var)` equals `sd`, so the plot does not visibly prove the asymmetric API.
  Use genuinely different quantities here (`sd` vs `se`, `se` vs `ci`, or
  lower/upper quantile distances) so the feature reads immediately.

- I would keep the README shorter than the plan currently suggests. Better split:
  README = pitch + one strong example per feature family; vignettes = the fuller
  modelling/use-case walkthroughs. A very comprehensive README will compete with
  the vignettes instead of feeding them.

- The functional-programming tip is worth keeping, but as a compact aside. The
  current "same layer, different entry points" paragraph already makes the point;
  avoid letting the README turn into a reference manual.

- If you want "more interesting plots", the strongest upgrade is not more layers
  everywhere; it is choosing one plot per feature that answers a recognizable
  question. The residual example already does that better than the earlier ones.
============ NOTE ============ -->
