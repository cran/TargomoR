
# API Helpers -------------------------------------------------------------

#' Targomo API base URL
#'
targomoAPI <- function() {
  "https://api.targomo.com/"
}

#' Create Request URL
#'
#' Function to create the request URL.
#'
#' @param region The Targomo region.
#' @param end_point The API end_point.
#'
#' @return Character string, the URL of the chosen endpoint
#'
createRequestURL <- function(region, end_point) {
  paste0(targomoAPI(), region, "/v1/", end_point)
}


#' Derive Options
#'
#' Function to create options in a nested list structure suitable to be turned into JSON.
#'
#' @param options The output of \code{\link{targomoOptions}}.
#'
#' @return List of options correctly structured for converting to JSON and passing to the API
#'
deriveOptions <- function(options) {

  opts <- list()

  opts$edgeWeight <- options$edgeWeight
  opts$maxEdgeWeight <- options$maxEdgeWeight
  opts$elevation <- options$elevation
  opts$pathSerializer <- options$serializer

  opts$polygon <- leaflet::filterNULL(
    list(
      values = options$travelTimes,
      intersectionMode = options$intersectionMode,
      serializer = options$serializer,
      srid = options$srid,
      minPolygonHoleSize = options$minPolygonHoleSize,
      buffer = options$buffer,
      simplify = options$simplify,
      quadrantSegments = options$quadrantSegments,
      decimalPrecision = options$decimalPrecision
    )
  )

  opts$tm <- leaflet::filterNULL(
    list(
      tm = options$travelType,
      car = leaflet::filterNULL(
        list(rushHour = options$carRushHour)
      ),
      walk = leaflet::filterNULL(
        list(speed = options$walkSpeed,
             uphill = options$walkUpHillAdjustment,
             downhill = options$walkDownHillAdjustment)
      ),
      bike = leaflet::filterNULL(
        list(speed = options$bikeSpeed,
             uphill = options$bikeUpHillAdjustment,
             downhill = options$bikeDownHillAdjustment)
      ),
      transit = leaflet::filterNULL(
        list(
          frame = leaflet::filterNULL(
            list(date = options$transitDate,
                 time = options$transitTime,
                 duration = options$transitDuration,
                 maxWalkingTimeFromSource = options$transitMaxWalkingTimeFromSource,
                 maxWalkingTimeToTarget = options$transitMaxWalkingTimeToTarget,
                 earliestArrival = options$transitEarliestArrival)
          ),
          maxTransfers = options$transitMaxTransfers
        )
      )
    )
  )

  opts <- leaflet::filterNULL(opts)

  opts

}


#' Derive Sources/Targets
#'
#' Function to create the sources needed to query the Targomo API.
#'
#' @param data The data object
#' @param lat,lng The lat/lng vectors or formulae to resolve
#' @param id The id vector or formula to resolve
#' @param points A processed data object (for sources/targets).
#' @param options A processed options object (for sources).
#'
#' @return A data.frame of sources/targets, with IDs attached.
#'
#' @name deriveSources
NULL

#' @rdname deriveSources
createIds <- function(data = NULL, id = NULL) {

  if (is.null(data)) {
    if (is.null(id)) {
      NULL
    } else {
      id
    }
  } else {
    if (is.null(id)) {
      seq_len(nrow(data))
    } else if (inherits(id, "formula")) {
      if (length(id) != 2L) {
        stop("Unexpected 2-sided formula: ", deparse(id))
      }
      as.character(eval(id[[2]], data, environment(data)))
    } else if (length(id) != nrow(data)) {
      stop("'id' values different length to 'data'")
    } else {
      id
    }
  }

}

#' @rdname deriveSources
createPoints <- function(data = NULL, lat = NULL, lng = NULL, id = NULL) {

  points <- leaflet::derivePoints(data, lng, lat, is.null(lng), is.null(lat))
  ids <- createIds(data, id)
  if (!is.null(ids)) {
    points$id <- ids
  } else {
    points$id <- seq_along(points$lat)
  }
  points <- points[!is.na(points$lat) & !is.na(points$lng), ]

  points

}

#' @rdname deriveSources
deriveSources <- function(points, options) {

  tm <- options$tm[options$tm$tm]
  sources <- vector(mode = "list", length = nrow(points))

  for (i in seq_along(points$lat)) {
    pt <- points[i, ]
    sources[[i]] <- list("id" = pt$id, "lat" = pt$lat, "lng" = pt$lng, "tm" = tm)
  }

  sources

}

#' @rdname deriveSources
deriveTargets <- function(points) {

  targets <- vector(mode = "list", length = nrow(points))

  for (i in seq_along(points$lat)) {
    pt <- points[i, ]
    targets[[i]] <- list("id" = pt$id, "lat" = pt$lat, "lng" = pt$lng)
  }

  targets

}

#' Create Request Body
#'
#' Function to create a request body using the sources and options given.
#'
#' @param service The Targomo Service to create a body for - 'polygon', 'time', 'route'.
#' @param sources A processed sources object to pass to the API.
#' @param targets A processed targets object (optional).
#' @param options A processed options list.
#'
#' @return A JSON request body to be POST-ed to the API
#'
createRequestBody <- function(service, sources = NULL, targets = NULL, options) {

  if (is.null(service)) {
    stop("No Targomo service specified")
  }

  if (is.null(sources)) {
    stop("No source data provided")
  }

  fields <- c("edgeWeight", "maxEdgeWeight", "elevation", "sources", "targets",
              if (service == "polygon") "polygon" else NULL,
              if (service == "route") "pathSerializer" else NULL)

  options$sources <- sources
  options$targets <- targets
  options <- leaflet::filterNULL(options[fields])

  body <- jsonlite::toJSON(options, auto_unbox = TRUE, pretty = TRUE)

  body

}

#' Call the Targomo API
#'
#' Function to wrap aroung \code{httr::POST}, sending the request body to the API.
#'
#' @param api_key The Targomo API key.
#' @param region The Targomo region.
#' @param service The Targomo service - 'polygon', 'route', or 'time'.
#' @param body A request body made with \code{\link{createRequestBody}}.
#' @param config Config options to pass to \code{httr::POST} e.g. proxy settings
#' @param verbose Display info on the API call?
#' @param progress Display a progress bar?
#' @param timeout Timeout in seconds (leave NULL for no timeout/curl default).
#'
#' @return A httr response object with the API response (whether successful or not).
#'
callTargomoAPI <- function(api_key = Sys.getenv("TARGOMO_API_KEY"),
                           region = Sys.getenv("TARGOMO_REGION"),
                           service, body, config = list(),
                           verbose = FALSE, progress = FALSE,
                           timeout = NULL) {

  url <- createRequestURL(region, service)

  response <- httr::POST(url = url, config = config,
                         query = list(key = api_key),
                         body = body, encode = "json",
                         if (verbose) httr::verbose(),
                         if (progress) httr::progress(),
                         if (!is.null(timeout)) httr::timeout(timeout))

  response

}

#' Message if multiple Travel Modes supplied
#'
#' @param tms A vector of travel modes
#'
messageMultipleTravelModes <- function(tms) {
  if (length(tms) > 1) {
    message("Multiple (", length(tms), ") travel types supplied - treating each in turn.\n",
            "This will make ", length(tms), " calls to the API.")
  }
}
