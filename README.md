# ggerror <img src="assets/hex.png" alt="ggerror hex logo" align="right" height="150"/>

[![CRAN](https://www.r-pkg.org/badges/version/ggerror)](https://cran.r-project.org/package=ggerror) [![R-CMD-check](https://github.com/iamyannc/ggerror/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/iamyannc/ggerror/actions/workflows/R-CMD-check.yaml) [![ORCID](https://img.shields.io/badge/ORCID-0009--0009--0509--3609-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0009-0009-0509-3609)

`ggerror` is a lightweight extension of the **ggplot2 ecosystem** designed to simplify error visualizations. It replaces the manual wiring of `ymin`/`ymax` or `xmin`/`xmax` with a single, intuitive `error` aesthetic.

### Why use `ggerror`?
* **Intuitive:** Declare a single `error` aesthetic and let the package infer orientation automatically.
* **Safer:** Built-in validation via `cli` prevents mismatched aesthetics and orientation errors.
* **Standard:** Adheres strictly to `ggplot2` behaviors, `ggproto` best practices, and orientation inference.

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