#' @name ridl.conn
#' @rdname ridl.conn
#' @title  Connect to UNHCR ridl server http://ridl.unhcr.org
#'
#' @description  Connect to UNHCR ridl server using API key stored in your .Renviron file

#' @export ridl.conn
#'
#' @author Hisham Galal

ridl.conn <- function() {
  rvest::html_session("https://ridl.unhcr.org/",
                      httr::add_headers("X-CKAN-API-Key" = Sys.getenv("RIDL_API_KEY")))
}
#' @name ridl.index
#' @rdname ridl.index
#' @title  Get a list of projects in ridl http://ridl.unhcr.org
#'
#' @description  Get a list of projects in ridl

#' @export ridl.index
#'
#' @author Hisham Galal
ridl.index <- function() {
  r <- ridl.conn()

  if(httr::http_error(r$response)) {
    warning("[INDEXER]: Failed to index RIDL - ", httr::http_status(r)$message, ". Skipping...",
            call. = FALSE, noBreaks. = TRUE)
    return(empty.index())
  }

  # FIXME: Need a loop to retrieve more than the first 1000 datasets
  r <- rvest::jump_to(r, "/api/3/action/package_search?rows=1000")

  result <-
    r$response %>%
    httr::content(as = "text") %>%
    jsonlite::fromJSON() %>%
    purrr::pluck("result", "results") %>%
    tibble::as_tibble() %>%
    dplyr::select(dsname = name, dsdesc = title, resources) %>%
    tidyr::unnest(resources) %>%
    dplyr::transmute(
      srcname = "ridl", srcdesc = "Raw Internal Data Library",
      dsname, dsdesc,
      filename = fs::path_file(url), filedesc = filename,
      url)

  # This is basically a poor-man's HEAD request since the API neither supports HEAD requests
  # nor does it have any method for retrieving the list of datasets that a user has access to.
  accessible <-
    result %>%
    dplyr::group_by(dsname) %>%
    dplyr::summarize(
      candownload =
        purrr::quietly(rvest::jump_to)(r, dplyr::first(url), httr::add_headers(Range = "bytes=0-0")) %>%
        purrr::pluck("result", "response") %>%
        { purrr::negate(httr::http_error)(.) },
      .groups = "drop") %>%
    dplyr::filter(candownload)

  result <- result %>% dplyr::semi_join(accessible, by = "dsname")

  result
}
