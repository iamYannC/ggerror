# ggerror

[![ORCID](https://img.shields.io/badge/ORCID-0009--0009--0509--3609-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0009-0009-0509-3609)

`ggerror` simplifies **ggplot2**’s error geoms and introduces asymetric
error bars and customization.

Instead of wiring `ymin` / `ymax` or `xmin` / `xmax` by hand, you supply
`error` (or `error_neg` + `error_pos`) and `ggerror` will do the rest
for you. It can be as simple as providing a single `error` argument, yet
offer full customization options for per-side styling.

### Installation

``` r
pak::pak('iamyannc/ggerror')

library(ggplot2)
library(ggerror)

p <- ggplot(mtcars, aes(mpg, rownames(mtcars))) +
  geom_point()

# Symmetric error bars, using default geom errorbar
p + geom_error(aes(error = drat))

# Asymmetric error bars, using geom_error_pointrange and per-side styling
p + geom_error_pointrange(aes(error_neg = drat / 2, error_pos = drat, linetype_neg = "dashed"))

# One-sided error bars, using the error_geom argument
p + geom_error(error_geom = "linerange", aes(error_neg = NA, error_pos = drat))
```

#### Symmetric error bars

[![ggerror example geoms -
symmetric](reference/figures/examples_basic.png)](https://iamyannc.github.io/ggerror/man/figures/examples_basic.png)

#### Asymmetric error bars

[![ggerror example geoms -
asymmetric](reference/figures/examples_asymmetric.png)](https://iamyannc.github.io/ggerror/man/figures/examples_asymmetric.png)

For detailed examples of symmetric, asymmetric, one-sided, and per-side
styling, see
[`vignette("ggerror")`](https://iamyannc.github.io/ggerror/articles/ggerror.html).

### Supported geoms

| ggplot2 Base      | `geom_error(error_geom = ...)` | Specific Wrapper                                                                        |
|:------------------|:-------------------------------|:----------------------------------------------------------------------------------------|
| `geom_errorbar`   | `"errorbar"` (default)         | [`geom_error()`](https://iamyannc.github.io/ggerror/reference/geom_error.md)            |
| `geom_linerange`  | `"linerange"`                  | [`geom_error_linerange()`](https://iamyannc.github.io/ggerror/reference/geom_error.md)  |
| `geom_pointrange` | `"pointrange"`                 | [`geom_error_pointrange()`](https://iamyannc.github.io/ggerror/reference/geom_error.md) |
| `geom_crossbar`   | `"crossbar"`                   | [`geom_error_crossbar()`](https://iamyannc.github.io/ggerror/reference/geom_error.md)   |

### Disclaimer

This package was developed with the assistance of AI tools. All code has
been reviewed by the author, who remains responsible for its quality.
Ideas for new geoms are welcome.
