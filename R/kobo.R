kobo.conn <- function() {
  rvest::html_session("https://kobo.unhcr.org/",
                      httr::add_headers(
                        Authorization = glue::glue("Token {Sys.getenv('KOBO_API_KEY')}")))
}

kobo.index <- function() {
  r <- kobo.conn()

  if(httr::http_error(r$response)) {
    warning("[INDEXER]: Failed to index KoBo - ", httr::http_status(r)$message, ". Skipping...",
            call. = FALSE, noBreaks. = TRUE)
    return(empty.index())
  }

  r <- rvest::jump_to(r, "/api/v2/assets")

  assets <-
    r$response %>%
    httr::content() %>%
    purrr::pluck("results") %>%
    purrr::keep(~.$asset_type == "survey") %>%
    purrr::map_dfr(~tibble::tibble(uid = purrr::pluck(., "uid"), dsname = purrr::pluck(., "name")))

  r <- rvest::jump_to(r, "/exports")

  exports <-
    r$response %>%
    httr::content() %>%
    purrr::pluck("results") %>%
    purrr::keep(~!is.null(.$result)) %>%
    purrr::map_dfr(
      ~tibble::tibble(
        uid = stringr::str_match(purrr::pluck(., "data", "source"), ".*/(.*)/$")[,2],
        url = purrr::pluck(., "result"),
        filename = purrr::map_chr(fs::path_file(url), URLdecode))) %>%
    dplyr::left_join(assets, by = "uid") %>%
    tidyr::replace_na(list(dsname = "==ARCHIVED EXPORTS=="))

  result <-
    dplyr::bind_rows(
      assets %>%
        dplyr::mutate(filename = "form.xls",
                      url = stringr::str_c("https://kobo.unhcr.org/api/v2/assets/", uid, ".xls")),
      assets %>%
        dplyr::mutate(filename = "data.json",
                      url = stringr::str_c("https://kobo.unhcr.org/api/v2/assets/", uid, "/data.json")),
      exports)

  result <-
    result %>%
    dplyr::transmute(
      srcname = "kobo", srcdesc = "KoBoToolbox",
      dsname, dsdesc = dsname,
      filename, filedesc = filename,
      url)

  result
}
