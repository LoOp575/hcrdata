empty.index <- function() {
  tibble::tibble(
    srcname = character(), srcdesc = character(),
    dsname = character(), dsdesc = character(),
    filename = character(), filedesc = character(),
    url = character())
}

#' @export
hcrindex <- function(cache = TRUE) {
  indexfile <- fs::path(rappdirs::user_cache_dir("hcrdata", "unhcr"), "index.csv")

  if(!cache ||
     !fs::file_exists(indexfile) ||
     difftime(Sys.time(),
              fs::file_info(indexfile)$modification_time,
              units = "days") > 1) {
    result <- dplyr::bind_rows(kobo.index(), mdl.index(), ridl.index())
    fs::dir_create(fs::path_dir(indexfile))
    readr::write_csv(result, indexfile)
  } else {
    result <- purrr::quietly(readr::read_csv)(indexfile)$result
  }

  result
}

#' @export
hcrfetch <- function(src, dataset, file,
                     path = here::here("data", dataset, file),
                     cache = TRUE) {
  if(cache && fs::file_exists(path)) {
    return(path)
  }

  idx <- hcrindex(cache)

  url <-
    idx %>%
    dplyr::filter(srcname == src, dsname == dataset, filename == file) %>%
    dplyr::pull(url)

  if (purrr::is_empty(url)) {
    stop("File not found")
  }

  fs::dir_create(fs::path_dir(path))

  r <-
    switch(
      src,
      "kobo" = kobo.conn(),
      "mdl" = mdl.conn(),
      "ridl" = ridl.conn())

  r <- r %>% rvest::jump_to(url, httr::write_disk(path, overwrite = TRUE))

  if(httr::http_error(r$response)) {
    stop("File download failed - ", httr::http_status(r)$message)
  }

  path
}
