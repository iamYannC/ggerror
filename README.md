# ggerror <img src="assets/hex.png" alt="ggerror hex logo" align="right" height="150"/>

[![ORCID](https://img.shields.io/badge/ORCID-0009--0009--0509--3609-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0009-0009-0509-3609)

`ggerror` is a lightweight extension of the **ggplot2 ecosystem** designed to simplify error visualizations. It replaces the manual wiring of `ymin`/`ymax` or `xmin`/`xmax` with a single, intuitive `error` aesthetic.

Beyond being intuitive, it is also safer: it eliminates trial-and-error when defining range boundaries (e.g., "is it xmax or ymax?" "what orientation should i define?") and prevents common mistakes, such as accidentally swapping minimum and maximum values.
It is also flexible enough that you can pass any aesthetic you'd normally pass to the original geom_* (error) functions.

### Installation
```r
# Install from GitHub
pak::pak('iamyannc/ggerror')

library(ggplot2)
library(ggerror)

# Orientation is inferred automatically (e.g., discrete y-axis)
ggplot(mtcars, aes(mpg, factor(cyl))) +
  geom_point() +
  geom_error(aes(error = drat))

# Easily switch types using the same mapping
geom_error(aes(error = drat), err_type = "pointrange")

```

### Supported geoms

| ggplot2 Base | `geom_error(err_type = ...)` | Specific Wrapper |
| :--- | :--- | :--- |
| `geom_errorbar` | `"errorbar"` (default) | `geom_error()` |
| `geom_linerange` | `"linerange"` | `geom_error_linerange()` |
| `geom_pointrange` | `"pointrange"` | `geom_error_pointrange()` |
| `geom_crossbar` | `"crossbar"` | `geom_error_crossbar()` |
