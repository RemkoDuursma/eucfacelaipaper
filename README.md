# Leaf area index at the EucFACE
[![DOI](https://zenodo.org/badge/11128/RemkoDuursma/eucfacelaipaper.svg)](https://zenodo.org/badge/latestdoi/11128/RemkoDuursma/eucfacelaipaper)


This repository contains the code for the paper:
  

Remko A. Duursma, Teresa E. Gimeno, Matthias M. Boer, Kristine Y. Crous, Mark G. Tjoelker, David S. Ellsworth, 2016, **Canopy leaf area of a mature evergreen Eucalyptus woodland does not respond to elevated atmospheric [CO~2~] but tracks water availability**. [Global Change Biology 22, 1666-1676](http://onlinelibrary.wiley.com/doi/10.1111/gcb.13151/full).


## Data

The raw data used by this repository is published here: http://dx.doi.org/10.4225/35/563159f223739


## Instructions

To generate **all figures and the manuscript** (.docx, using rmarkdown), you should be able to do:

```r
source("run.R")
```

This generates figures in PDF in the subdirectory `output/figures`, and two Word documents `manuscript.docx` and `manuscript_SuppInfo.docx`. The Word documents are made using the `rmarkdown` and `knitr` packages, based on the `.Rmd` files in the repository.


## Dependencies

The code will attempt to install any missing packages. If you have problems with package dependencies, here is the list of packages you need to have (and their dependencies). All of these packages are on CRAN.

```
dplyr,doBy,gplots,mgcv,stringr,Hmisc,lubridate,rmarkdown,broom,lme4,lmerTest,car,reporttools
```

For the conversion of the markdown document, you will need to use Rstudio or have an installation of Pandoc. 

You also need an internet connection: first to download the raw data used in the repository, and also when rendering the manuscript. 



