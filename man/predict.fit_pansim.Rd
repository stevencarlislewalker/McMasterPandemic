% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods.R
\name{predict.fit_pansim}
\alias{predict.fit_pansim}
\alias{plot.fit_pansim}
\title{make forecasts from sim}
\usage{
\method{predict}{fit_pansim}(
  object,
  end_date = NULL,
  stoch = NULL,
  stoch_start = NULL,
  keep_vars = c("H", "ICU", "death", "hosp", "incidence", "report", "cumRep",
    "newTests/1000"),
  ensemble = FALSE,
  new_params = NULL,
  Sigma = NULL,
  scale_Sigma = 1,
  ...
)

\method{plot}{fit_pansim}(
  x,
  predict_args = NULL,
  data = NULL,
  break_dates = NULL,
  dlspace = 1,
  limspace = 10,
  add_tests = FALSE,
  add_ICU_cap = FALSE,
  mult_var = NULL,
  directlabels = TRUE,
  log = TRUE,
  log_lwr = 1,
  ...
)
}
\arguments{
\item{object}{a fitted object}

\item{end_date}{ending date for sim}

\item{stoch}{stochasticity}

\item{stoch_start}{stoch starting date}

\item{keep_vars}{...}

\item{ensemble}{run ensemble?}

\item{new_params}{parameters to update in base parameters (e.g. adding stochastic parameters)}

\item{Sigma}{covariance matrix}

\item{scale_Sigma}{inflate/deflate covariance matrix}

\item{...}{extra args (passed to forecast_ensemble)}

\item{x}{a calibrated object (result from \code{\link{calibrate}}) or a prediction (from \code{\link{predict.fit_pansim}})}

\item{predict_args}{additional arguments to pass to predict}

\item{data}{original time series data}

\item{break_dates}{breakpoints}

\item{dlspace}{spacing for direct labels (not working)}

\item{limspace}{extra space (in days) to add to make room for direct labels}

\item{add_tests}{plot newTests/1000?}

\item{add_ICU_cap}{include horizontal lines showing ICU capacity?}

\item{mult_var}{variable in data set indicating multiple forecast types to compare}

\item{directlabels}{use direct labels?}

\item{log}{use a log10 scale for the y axis?}

\item{log_lwr}{lower limit when using log scale}
}
\description{
make forecasts from sim
}
\examples{
pp1 <- predict(ont_cal1, keep_vars="Rt")
## example of hacking params
ont_cal2 <- ont_cal1
ont_cal2$forecast_args$base_params["zeta"] <- 4
pp2 <- predict(ont_cal2, keep_vars="Rt")
## if zeta is fitted probably need to hack x$mle2@coef, e.g.
ont_cal3 <- ont_cal1
## increase beta0 (from -0.34) rather than
## mess with zeta, since phenom het isn't
## estimated in this fit
ont_cal3$mle2@fullcoef["params.log_beta0"] <- 0
pp3 <- predict(ont_cal3, keep_vars="Rt")
pp <- dplyr::bind_rows(base=pp1,zeta=pp2,beta0=pp3, .id="fit")
if (require("ggplot2")) {
   ggplot(pp,aes(date,value,colour=fit))+geom_line()
}
\dontrun{
## non-pos-def vcov ... ???
predict(ont_cal_2brks,ensemble=TRUE)
}
}
