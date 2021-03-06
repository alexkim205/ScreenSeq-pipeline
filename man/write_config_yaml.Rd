% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{write_config_yaml}
\alias{write_config_yaml}
\title{Write configuration yaml file for Perl input.}
\usage{
write_config_yaml(plates, yaml_fo)
}
\arguments{
\item{plates}{A list of plate lists that carries all the well information}

\item{yaml_fo}{A file path to write the configuration yaml to}
}
\value{
NA
}
\description{
\code{write_wells_info} writes per well information to a easily readable YAML
file.
}
\details{
Read in the parameters in \code{parameters.R} and create a configuration YAML
file that can act as an input for Sasha's Perl scripts.
}
