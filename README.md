# [hcrdata](https://unhcr-web.github.io/hcrdata/docs)

An RStudio addin that wraps access to UNHCR data behind a uniform interface.

It can be installed from github with `devtools::install_github("UNHCR-WEB/hcrdata")`.

Currently supported data sources:
* __kobo__:UNHCR corporate server for survey data collection based on [Kobotoolbox](https://www.kobotoolbox.org/): [http://kobo.unhcr.org](http://kobo.unhcr.org)
* __ridl__: Raw Internal Data Library, UNHCR internal instance of [CKAN data portal](https://ckan.org/) for data documentation: [http://ridl.unhcr.org](http://ridl.unhcr.org)
* __mdl__: Microdata Library, UNHCR instance of [NADA](https://nada.ihsn.org/) for the publication of anonymized microdata: [http://microdata.unhcr.org](http://microdata.unhcr.org)

With more to come (_popstats, rsq, etc..._).

# Usage
The package expects to find your API keys / access credentials in environment variables. The easiest way to get them there and persist your settings is to store them in your `.Renviron` file which is automatically read by R on startup. 

Ypu can retrieve your `API key` for UNHCR kobo server in the [account setting page](https://kobo.unhcr.org/#/account-settings) and in RIDL in your own [user page](https://ridl.unhcr.org/user/).

You can either edit directly the `.Renviron` file or access it by calling `usethis::edit_r_environ()` (assuming you have the `usethis` package installed) and entering:

    KOBO_API_KEY=xxxxxxxxx
    RIDL_API_KEY=xxxxxxxxx
    MDL_ACCESS_CREDS=user:password

Once that's done, restart your R session to make sure that the variables are loaded.

Then open a new R script within a RStudio project.

You should then be able to launch the "data browser" with from the addins menu:

 1. select the source
 2. go to the dataset tab and select the project you want to pull data from
 3. go to the files tab and select the specific file you want to retrieve from the project.
 4. press the load data button and the R statement to pull this file from your project will be automatically inserted in your blank R script tab


![preview](https://i.imgur.com/1hEUFkd.png)

note that if you pull data from a kobo project, you can use a live data feed. This can be usefull for instance in the context of [High frequency Check]()

in this case the following will conveniently pull directly the data as a data frame
``` r
data <-
  hcrdata::hcrfetch(
    src = "kobo",
    dataset = "High Frequency Survey - Remote or in-person interviews",
    file = "data.json") %>%
  jsonlite::fromJSON() %>%
  purrr::pluck("results") %>%
  tibble::as_tibble() %>%
  purrr::set_names(~stringr::str_replace_all(., "(\\/)", "."))
```

Building this package
`devtools::document()`

`devtools::check(document = FALSE)`

`pkgdown::build_site()`
