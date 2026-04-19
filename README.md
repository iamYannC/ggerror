# ggerror <img src="man/figures/logo.png" alt="ggerror hex logo" align="right" height="150"/>

[![ORCID](https://img.shields.io/badge/ORCID-0009--0009--0509--3609-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0009-0009-0509-3609)

`ggerror` is a lightweight extension of the **ggplot2 ecosystem** designed to simplify error visualizations. It replaces the manual wiring of `ymin`/`ymax` or `xmin`/`xmax` with a single, intuitive `error` aesthetic.

### Motivation
Beyond being intuitive, it is also safer: it eliminates trial-and-error when defining range boundaries (e.g., "is it xmax or ymax?" "Is it x or y orientation?") and prevents common mistakes, such as swapping minimum and maximum values.
It is also flexible enough that you can pass any aesthetic you'd normally pass to the original geom_* (error) functions.

### Installation
```r
# Install from GitHub
pak::pak('iamyannc/ggerror')

library(ggplot2)
library(ggerror)

p <- ggplot(mtcars, aes(mpg, rownames(mtcars))) +
     geom_point()
# Orientation is inferred automatically, defaults to `errorbar`
 p + geom_error(aes(error = drat))

# Either use the general `geom_error` and specify `err_type`,
 # Or the explicit geom_error_*
p + geom_error(aes(error = drat),err_type = "crossbar")
p + geom_error_crossbar(aes(error = drat))
# They are the same.

# You can also pass error to `ggplot()`
ggplot(mtcars, aes(mpg, rownames(mtcars), error = drat)) +
  geom_point() + geom_error_linerange()


# Having a general geom allows for easy functional programming approach:
supported_types <- c('errorbar', 'crossbar', 'linerange', 'pointrange')
purrr::map(supported_types, \(err) p + geom_error(aes(error = drat), err_type = err))

```

### Supported geoms

| ggplot2 Base | `geom_error(err_type = ...)` | Specific Wrapper |
| :--- | :--- | :--- |
| `geom_errorbar` | `"errorbar"` (default) | `geom_error()` |
| `geom_linerange` | `"linerange"` | `geom_error_linerange()` |
| `geom_pointrange` | `"pointrange"` | `geom_error_pointrange()` |
| `geom_crossbar` | `"crossbar"` | `geom_error_crossbar()` |

### Disclaimer
This small wrapper-package was developed with the assistance of AI tools, primarily Claude Code. All code has been reviewed by the author, who remains fully responsible for its quality.
Ideas for new geoms are welcome. Open an issue for any bug report or feature request.
Thank you for reading and for using this package.
*Yann*