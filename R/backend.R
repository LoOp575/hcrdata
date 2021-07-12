#' @name empty.index
#' @rdname empty.index
#' @title  prepare an empty index
#'
#' @description  prepare an empty index

#' @export empty.index
#'
#' @author Hisham Galal

empty.index <- function() {
  tibble::tibble(
    srcname = character(), srcdesc = character(),
    dsname = character(), dsdesc = character(),
    filename = character(), filedesc = character(),
    url = character())
}

#' @name hcrindex
#' @rdname hcrindex
#' @title  fill  empty index
#'
#' @description  fill  empty index

#' @export hcrindex
#'
#' @author Hisham Galal
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
    if (nrow(result) == 0)
      hcrindex(FALSE)
  }

  result
}

#' @name hcrfetch
#' @rdname hcrfetch
#' @title  function to fetch data directly
#'
#' @description  function to fetch data directly

#' @export hcrfetch
#'
#' @author Hisham Galal
hcrfetch <- function(src, dataset, file,
                     path = here::here("data-raw", fs::path_sanitize(dataset), fs::path_sanitize(file)),
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

  r <- r %>% rvest::session_jump_to(url, httr::write_disk(path, overwrite = TRUE))

  if(httr::http_error(r$response)) {
    stop("File download failed - ", httr::http_status(r)$message)
  }

  path
}
