# package info
bzar.USER_AGENT = paste("bzar", packageVersion("bzar"), sep = " ")

# data source URLs
bzar.CONFIG_URL = "https://analytics.opendatahub.bz.it/layers-config.json"
bzar.BASE_URL   = "https://mobility.api.opendatahub.bz.it/v2"
bzar.AUTH_URL   = "https://auth.opendatahub.bz.it/auth/realms/noi/protocol/openid-connect/token"


# ------------------------------------------------------------------------------
#'
#' Get Station Types
#'
#' Get the available station types.
#'
#' @return A vector with the station types names.
#'
#' @export
# ------------------------------------------------------------------------------
bzar.get_station_types = function() {
    data = bzar.get_config()
    return(data[, "name"])
}


# ------------------------------------------------------------------------------
#'
#' Get Stations
#'
#' Given a station type, return a data frame with the available stations.
#' Use bzar.get_station_types() to get a vector of known station types.
#'
#' @param station_type The station type.
#'
#' @return A data frame with the station names and codes.
#'
#' @export
# ------------------------------------------------------------------------------
bzar.get_stations = function(station_type) {
    # get the URL path associated to the given station type
    data = bzar.get_config()
    path = ""
    for (row in 1:nrow(data)) {
        if (data[row, "name"] == station_type) {
            path = data[row, "path"]
        }
    }
    if (path == "") {
        stop("unknown station type - use bzar.get_station_types() to get a list of valid station types")
    }
    # download the list of stations for the given station type
    stations = httr::GET(
        paste(path, "?limit=-1&distinct=true&where=sactive.eq.true", sep = ""), 
        user_agent(bzar.USER_AGENT)
    )
    if (status_code(stations) != 200) {
        stop(paste("download failed with status = ", status_code(stations)))
    }
    stations = content(stations)$data
    name = character()
    code = character()
    for (s in 1:length(stations)) {
        name = c(name, stations[s][[1]]$sname)
        code = c(code, stations[s][[1]]$scode)
     }
    ret = data.frame(name = name, code = code)
    return(ret[order(ret$name), ])
}


# ------------------------------------------------------------------------------
#'
#' Get Data Sets
#'
#' Given a station type and a station code, return a data frame with the
#' available data sets. Use bzar.get_station_types() to get a vector of known
#' station types. Use bzar.get_stations() to get a data frame of known
#' station codes.
#'
#' @param station_type The station type.
#'
#' @param station_code The station code.
#'
#' @return A data frame with the data set name and units.
#'
#' @export
# ------------------------------------------------------------------------------
bzar.get_data_sets = function(station_type, station_code) {
    # get the URL path associated to the given station type
    data = bzar.get_config()
    path = ""
    for (row in 1:nrow(data)) {
        if (data[row, "name"] == station_type) {
            path = data[row, "path"]
        }
    }
    if (path == "") {
        stop("unknown station type - use bzar.get_station_types() to get a list of valid station types")
    }
    # download the list of data sets for the given station type and code
    stations = httr::GET(
        paste(path, "/*/?limit=-1&distinct=true&where=and%28scode.eq.%22", station_code , "%22%2Csactive.eq.true%29", sep = ""), 
        user_agent(bzar.USER_AGENT)
    )
    if (status_code(stations) != 200) {
        stop(paste("download failed with status = ", status_code(stations)))
    }
    stations = content(stations)$data
    name = character()
    unit = character()
    if (length(stations) == 0) {
        stop(paste("no data sets - are you sure the station code is valid? use bzar.get_stations(\"", station_type, "\") to get a list of valid stations", sep = ""))
    }
    for (s in 1:length(stations)) {
        name = c(name, stations[s][[1]]$tname)
        if (is.null(stations[s][[1]]$tunit)) {
            unit = c(unit, "")
        } else {
            unit = c(unit, stations[s][[1]]$tunit)
        }
     }
    ret = data.frame(name = name, unit = unit)
    return(ret[order(ret$name), ])

}


# ------------------------------------------------------------------------------
#'
#' Get Time Series Data
#'
#' Retrieve the time series data corresponding to the given station type,
#' station code, data set and time interval. Optionally specify the desired
#' sample period (defaults to smallest available).
#'
#' @param station_type The station type.
#'
#' @param station_code The station code.
#'
#' @param     data_set The data set.
#'
#' @param      from_ts Start (>=) of the interval as string of the form 
#'                     yyyy-MM-dd[T[HH][:mm][:ss][.SSS]][Z],
#'                     where Z is the timezone (e.g. +0200).
#'
#' @param        to_ts End (<) of the interval as string of the 
#'                     form yyyy-MM-dd[T[HH][:mm][:ss][.SSS]][Z], where Z
#'                     is the timezone (e.g. +0200).
#'
#' @param  period_hint The preferred sample period in seconds (defaults to
#'                     the smallest available).
#'
#' @param     username Authenticate the request as this user name (defaults
#'                     to "", meaning do not authenticate)
#'
#' @param     password Password for authentication (defaults to "")
#'
#' @return A data frame with the requested time series in the half-open interval [from_ts, to_ts).
#'
#' @export
# ------------------------------------------------------------------------------
bzar.get_data = function(station_type, station_code, data_set, from_ts, to_ts,
                         period_hint = 1, username = "", password = "") {
    # get the URL path associated to the given station type
    data = bzar.get_config()
    path = ""
    for (row in 1:nrow(data)) {
        if (data[row, "name"] == station_type) {
            path = data[row, "path"]
        }
    }
    if (path == "") {
        stop("unknown station type - use bzar.get_station_types() to get a list of valid station types")
    }
    auth = FALSE
    if (username != "") {
        body = list("grant_type" = "password",
                    "username" = username,
                    "password" = password,
                    "client_id" = "odh-generic-client")
        auth_response = httr::POST(bzar.AUTH_URL, body = body, encode = "form")
        if (status_code(auth_response) != 200) {
            stop(paste("authentication download failed with status = ", status_code(auth_response)))
        }
        auth_response = content(auth_response)
        access_token = auth_response$access_token
        auth = TRUE
    }
    dataurl = paste(path, "/", data_set, "/", from_ts, "/", to_ts,
                    "?limit=-1&distinct=true&select=mvalue,mvalidtime,mperiod&where=and%28scode.eq.%22",
                    station_code , "%22%2Csactive.eq.true%29", sep = "")
    if (auth) {
        data = httr::GET(dataurl, user_agent(bzar.USER_AGENT), add_headers(Authorization = paste("bearer ", access_token, sep="")))
    } else {
        data = httr::GET(dataurl, user_agent(bzar.USER_AGENT))
    }
    if (status_code(data) != 200) {
        stop(paste("download failed with status = ", status_code(data)))
    }
    data = content(data)$data
    period = character()
    time   = character()
    value  = character()
    if (length(data) > 0) {
        # find closest period available to period_hint
        closest_period = -1E9
        for (d in 1:length(data)) {
            p = data[d][[1]]$mperiod
            if (abs(p - period_hint) < abs(p - closest_period)) {
                closest_period = p
            }
        }
        # just copy the points where period = closest_period
        for (d in 1:length(data)) {
            if (data[d][[1]]$mperiod == closest_period) {
                time   = c(time, data[d][[1]]$mvalidtime)
                value  = c(value, data[d][[1]]$mvalue)
            }
        }
        time = strptime(time, "%Y-%m-%d %H:%M:%S", tz="UTC")
    }
    return(data.frame(time = time, value = as.numeric(as.character(value))))
}


# ------------------------------------------------------------------------------
# get the available station types and their associated base URLs
# (internal function)
# ------------------------------------------------------------------------------
bzar.get_config = function() {
    # get configuration
    config = httr::GET(bzar.CONFIG_URL) 
    if (status_code(config) != 200) {
        stop(paste("download of configuration file failed with status = ", status_code(config)))
    }
    # extract station type names and URL paths for the layers having
    # format = "integreen" and return them as a data.frame
    name = character()
    path = character()
    for (layer_group in content(config)) {
        for (layer in layer_group$layers) {
            if (layer$format == "integreen") {
                name = c(name, layer$id)
                path = c(path, paste(bzar.BASE_URL, "/flat/", paste(layer$stationType, collapse=","), sep = ""))
            }
        }
    }
    return(data.frame(name = name, path = path))
}
