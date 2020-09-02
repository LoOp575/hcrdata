mdl.conn <- function() {
  creds <- Sys.getenv("MDL_ACCESS_CREDS") %>% stringr::str_split(":") %>% purrr::as_vector()

  r <- rvest::html_session("https://microdata.unhcr.org/index.php/auth/login")
  f <- rvest::html_form(r)[[1]] %>% rvest::set_values(email = creds[1], password = creds[2])

  rvest::submit_form(r, f %>% purrr::list_modify(url = r$url))
}

mdl.index <- function() {
  r <- mdl.conn()

  if(httr::http_error(r$response)) {
    warning("[INDEXER]: Failed to index MDL - ", httr::http_status(r)$message, ". Skipping...",
            call. = FALSE, noBreaks. = TRUE)
    return(empty.index())
  }

  r <- rvest::jump_to(r, "https://microdata.unhcr.org/index.php/auth/profile")

  if(purrr::is_empty(rvest::html_node(r, "h2"))) {
    return(empty.index())
  }

  requests <-
    r %>%
    rvest::html_nodes("table") %>%
    dplyr::last() %>%
    rvest::html_nodes("td") %>%
    {
      tibble::tibble(
        link = .[seq(2, length(.), 4)] %>% rvest::html_nodes("a") %>% rvest::html_attr("href"),
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
        r <- rvest::jump_to(r, link)

        r %>%
          rvest::html_nodes("a[href*='access_licensed/download']") %>%
          .[seq(2, length(.), 2)] %>%
          purrr::map_dfr(
            ~tibble::tibble(
              filename = rvest::html_attr(., "title"),
              url = rvest::html_attr(., "href"))) %>%
          dplyr::mutate(
            uid =
              rvest::html_nodes(r, "a[href*='catalog/']") %>%
              head(1) %>%
              rvest::html_attr("href") %>%
              stringr::str_match("/(\\d+)/") %>%
              purrr::pluck(2))
      })

  datasets <-
    purrr::map_dfr(
      unique(files$uid),
      function(uid) {
        r <- rvest::jump_to(r, paste0("https://microdata.unhcr.org/index.php/catalog/", uid))

        tibble::tibble(
          uid = uid,
          dsname = rvest::html_nodes(r, "span[data-idno]") %>% rvest::html_attr("data-idno"),
          dsdesc = rvest::html_nodes(r, "h1") %>% rvest::html_text())
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
