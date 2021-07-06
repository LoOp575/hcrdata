#' @name ridl.conn
#' @rdname ridl.conn
#' @title  Connect to UNHCR ridl server http://ridl.unhcr.org
#'
#' @description  Connect to UNHCR ridl server using API key stored in your .Renviron file

#' @export ridl.conn
#'
#' @author Hisham Galal

ridl.conn <- function() {
  rvest::session("https://ridl.unhcr.org/",
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
  r <- purrr::quietly(ridl.conn)()$result

  if(httr::http_error(r$response)) {
    warning("[INDEXER]: Failed to index RIDL. Skipping...",
            call. = FALSE, noBreaks. = TRUE)
    return(empty.index())
  }

  get_resources <- function(r) {
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
  }

  # FIXME: Need a loop to retrieve more than the first 1000 datasets
  public <-
    rvest::session_jump_to(r, "/api/3/action/package_search?q=visibility:public&rows=1000") %>%
    get_resources()

  private <-
    rvest::session_jump_to(r, "/api/3/action/organization_list_for_user?permission=read") %>%
    purrr::pluck("response") %>%
    httr::content(as = "text") %>%
    jsonlite::fromJSON() %>%
    purrr::pluck("result") %>%
    dplyr::pull(id) %>%
    purrr::map_dfr(~rvest::session_jump_to(r, glue::glue("/api/3/action/package_search?q=owner_org:{.}&rows=1000")) %>%
                     purrr::possibly(get_resources, tibble::tibble())())

  dplyr::bind_rows(private, public) %>% dplyr::distinct()
}
