% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/routes.R
\name{createRoutePopup}
\alias{createRoutePopup}
\title{Create Route Popups}
\usage{
createRoutePopup(data, transit = FALSE, startEnd = transit)
}
\arguments{
\item{data}{The route data from which to create the popup.}

\item{transit}{Whether this is a transit route.}

\item{startEnd}{Whether to show information on the start and end points.}
}
\value{
A HTML string for the route segment popup
}
\description{
Function for constructing popups on routes.
}
