% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{add_d_log}
\alias{add_d_log}
\title{recursively log-ify expressions}
\usage{
add_d_log(x)
}
\arguments{
\item{x}{an expression}
}
\description{
recursively log-ify expressions
}
\examples{
add_d_log(~dnorm(a,b,c))
add_d_log(~sum(dnorm(a,b,c)))
}
\keyword{internal}
