% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/API.R
\name{callTargomoAPI}
\alias{callTargomoAPI}
\title{Call the Targomo API}
\usage{
callTargomoAPI(api_key = Sys.getenv("TARGOMO_API_KEY"),
  region = Sys.getenv("TARGOMO_REGION"), service, body,
  config = list(), verbose = FALSE, progress = FALSE,
  timeout = NULL)
}
\arguments{
\item{api_key}{The Targomo API key.}

\item{region}{The Targomo region.}

\item{service}{The Targomo service - 'polygon', 'route', or 'time'.}

\item{body}{A request body made with \code{\link{createRequestBody}}.}

\item{config}{Config options to pass to \code{httr::POST} e.g. proxy settings}

\item{verbose}{Display info on the API call?}

\item{progress}{Display a progress bar?}

\item{timeout}{Timeout in seconds (leave NULL for no timeout/curl default).}
}
\value{
A httr response object with the API response (whether successful or not).
}
\description{
Function to wrap aroung \code{httr::POST}, sending the request body to the API.
}
