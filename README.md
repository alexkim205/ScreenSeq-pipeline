ScreenSeq Pipeline README
================
Alex Kim
7/19/2018

## Background

This pipeline for the ScreenSeq technique was created to make running
experiments using this technology easier. Current methods involve
copying data from one spreadsheet to another to configuration files
which is time consuming and error prone. This attempts to make that
process less painful.

Future work would include R Shiny apps that augment experiment design
and data input (cell viability).

## Usage

1.  Navigate to the `R/` directory.

2.  
I plan to make this into a package so that the functions can be used
modularly, but for now the user will have to open up the `.R` files in
the `R/` directory manually.

``` r
summary(cars)
```

    ##      speed           dist       
    ##  Min.   : 4.0   Min.   :  2.00  
    ##  1st Qu.:12.0   1st Qu.: 26.00  
    ##  Median :15.0   Median : 36.00  
    ##  Mean   :15.4   Mean   : 42.98  
    ##  3rd Qu.:19.0   3rd Qu.: 56.00  
    ##  Max.   :25.0   Max.   :120.00

## Including Plots

You can also embed plots, for example:

![](README_files/figure-gfm/pressure-1.png)<!-- -->

Note that the `echo = FALSE` parameter was added to the code chunk to
prevent printing of the R code that generated the plot.
