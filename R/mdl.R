#' @name mdl.conn
#' @rdname mdl.conn
#' @title  Connect to UNHCR mdl server http://microdata.unhcr.org
#'
#' @description  Connect to UNHCR mdl server using API key stored in your .Renviron file

#' @export mdl.conn
#'
#' @author Hisham Galal
mdl.conn <- function() {
  creds <- Sys.getenv("MDL_ACCESS_CREDS") %>% stringr::str_split(":") %>% purrr::as_vector()

  r <- rvest::session("https://microdata.unhcr.org/index.php/auth/login")
  f <- rvest::html_form(r)[[1]] %>% rvest::html_form_set(email = creds[1], password = creds[2])

  purrr::quietly(rvest::session_submit)(r, f %>% purrr::list_modify(action = r$url)) %>%
    purrr::pluck("result")
}

#' @name mdl.index
#' @rdname mdl.index
#' @title  Get a list of projects in mdl http://microdata.unhcr.org
#'
#' @description  Get a list of projects in mdl

#' @export mdl.index
#'
#' @author Hisham Galal
mdl.index <- function() {
  r <- purrr::safely(mdl.conn)()$result

  r <- rvest::session_jump_to(r, "https://microdata.unhcr.org/index.php/auth/profile")

  if(is.null(httr::content(r$response)) || purrr::is_empty(rvest::html_element(r, "h2"))) {
    warning("[INDEXER]: Failed to index MDL. Skipping...",
            call. = FALSE, noBreaks. = TRUE)
    return(empty.index())
  }

  requests <-
    r %>%
    rvest::html_elements("table") %>%
    dplyr::last() %>%
    rvest::html_elements("td") %>%
    {
      tibble::tibble(
        link = .[seq(2, length(.), 4)] %>% rvest::html_elements("a") %>% rvest::html_attr("href"),
        status = .[seq(3, length(.), 4)] %>% rvest::html_text())
    } %>%
    dplyr::filter(status == "Approved")

  if (nrow(requests) == 0) {
    return(empty.index())
  }

  files <-
    purrr::map_dfr(
      requests$link,
      function(link) {
        r <- rvest::session_jump_to(r, link)

        r %>%
          rvest::html_elements("a[href*='access_licensed/download']") %>%
          .[seq(2, length(.), 2)] %>%
          purrr::map_dfr(
            ~tibble::tibble(
              filename = rvest::html_attr(., "title"),
              url = rvest::html_attr(., "href"))) %>%
          dplyr::mutate(
            uid =
              rvest::html_elements(r, "a[href*='catalog/']") %>%
              head(1) %>%
              rvest::html_attr("href") %>%
              stringr::str_match("/(\\d+)/") %>%
              purrr::pluck(2))
      })

  datasets <-
    purrr::map_dfr(
      unique(files$uid),
      function(uid) {
        r <- rvest::session_jump_to(r, paste0("https://microdata.unhcr.org/index.php/catalog/", uid))

        tibble::tibble(
          uid = uid,
          dsname = rvest::html_element(r, "span[data-idno]") %>% rvest::html_attr("data-idno"),
          dsdesc = rvest::html_elements(r, "h1") %>% rvest::html_text())
      })

  result <-
    dplyr::left_join(datasets, files, by = "uid") %>%
    dplyr::transmute(
      srcname = "mdl", srcdesc = "Microdata Library",
      dsname, dsdesc,
      filename, filedesc = filename,
      url)

  result
}
