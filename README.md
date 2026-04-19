# ggerror <img src="man/figures/logo.png" alt="ggerror hex logo" align="right" height="150"/>

[![ORCID](https://img.shields.io/badge/ORCID-0009--0009--0509--3609-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0009-0009-0509-3609)

`ggerror` is a lightweight wrapper around **ggplot2**'s error geoms.
It replaces manual `ymin` / `ymax` or `xmin` / `xmax` wiring with one
`error` aesthetic, automatic orientation inference, and a single dispatch
point for the core range geoms.

### Motivation
It reduces the easy-to-make mistakes in error-bar code: swapping bounds,
choosing the wrong orientation, or reaching for the wrong geom variant.
It also keeps the familiar `ggplot2` styling surface, including asymmetric
errors and fixed per-side styling.

### Installation
```r
pak::pak('iamyannc/ggerror')

library(ggplot2)
library(ggerror)

p <- ggplot(mtcars, aes(mpg, rownames(mtcars))) +
  geom_point()

p + geom_error(aes(error = drat))
```

For a full tour of symmetric, asymmetric, one-sided, and per-side styling
patterns, see `vignette("ggerror")`.

<a href="man/figures/examples.png">
  <img src="man/figures/examples.png" alt="ggerror example geoms" width="100%" />
</a>

### Supported geoms

| ggplot2 Base | `geom_error(error_geom = ...)` | Specific Wrapper |
| :--- | :--- | :--- |
| `geom_errorbar` | `"errorbar"` (default) | `geom_error()` |
| `geom_linerange` | `"linerange"` | `geom_error_linerange()` |
| `geom_pointrange` | `"pointrange"` | `geom_error_pointrange()` |
| `geom_crossbar` | `"crossbar"` | `geom_error_crossbar()` |

### Disclaimer
This package was developed with the assistance of AI tools.
All code has been reviewed by the author, who remains responsible for its
quality.
Ideas for new geoms are welcome.
