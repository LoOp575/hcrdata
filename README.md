# [hcrdata](https://unhcr-web.github.io/hcrdata/docs)

An RStudio addin that wraps access to UNHCR data behind a uniform interface.

It can be installed from github with `devtools::install_github("UNHCR-WEB/hcrdata")`.

Currently supported data sources:
* __kobo__:UNHCR corporate server for survey data collection based on [Kobotoolbox](https://www.kobotoolbox.org/): [http://kobo.unhcr.org](http://kobo.unhcr.org)
* __ridl__: Raw Internal Data Library, UNHCR internal instance of [CKAN data portal](https://ckan.org/) for data documentation: [http://ridl.unhcr.org](http://ridl.unhcr.org)
* __mdl__: Microdata Library, UNHCR instance of [NADA](https://nada.ihsn.org/) for the publication of anonymized microdata: [http://microdata.unhcr.org](http://microdata.unhcr.org)

With more to come (_popstats, rsq, etc..._).

> This package is part of `unhcrverse`, a set of packages to ease the production of statistical evidence and data stories. You can install them all with the following:

```r
## Use UNHCR Open data - https://unhcr.github.io/unhcrdatapackage/docs/
remotes::install_github('unhcr/unhcrdatapackage’)
## API to connect to internal data source - https://unhcr-web.github.io/hcrdata/docs/
remotes::install_github('unhcr-web/hcrdata’)
## Perform High Frequency Check https://unhcr.github.io/HighFrequencyChecks/docs/
remotes::install_github('unhcr-web/HighFrequencyChecks’)
## Process data crunching for survey dataset - https://unhcr.github.io/koboloadeR/docs/
remotes::install_github('unhcr/koboloadeR’)
## Use UNHCR graphical template- https://unhcr-web.github.io/unhcRstyle/docs/
remotes::install_github('unhcr-web/unhcRstyle')
```

# Use Cases

Using API calls in your analysis scripts can be quite convenient in multiple situations:

 * During data collection, it is important to perform [High frequency Check](https://github.com/unhcr/HighFrequencyChecks) in order to monitor the quality of the data collection process. Using the API call, you can further __automate__ those checks;

 * Once the survey is completed in KoboToolbox, data shall be extracted and then documented and uploaded in RIDL. Performing those tasks through scripts can be a lot quicker, specifically when a __dataset with similar metadata shall be split__ between different data containers;
 
 * When writing an analytic piece with Rmd, being able to include in the Rmd the exact location of the RIDL data container or Microdata catalog allows to increase __reproducibility__.

# Usage

The package expects to find your API keys / access credentials in environment variables. The easiest way to get them there and persist your settings is to store them in your `.Renviron` file which is automatically read by R on startup. 

You can retrieve your `API key` for UNHCR kobo server in the [account setting page](https://kobo.unhcr.org/#/account-settings) and in RIDL in your own [user page](https://ridl.unhcr.org/user/).

You can either edit directly the `.Renviron` file or access it by calling `usethis::edit_r_environ()` (assuming you have the `usethis` package installed) and entering:

    KOBO_API_KEY=xxxxxxxxx
    RIDL_API_KEY=xxxxxxxxx
    MDL_ACCESS_CREDS=user:password

Once that's done, restart your R session to make sure that the variables are loaded.

Then open a new R script within a new RStudio project.

You should then be able to launch the "data browser" within [Rstudio addins](https://rstudio.github.io/rstudio-extensions/rstudio_addins.html) menu:

 1. select the source
 2. go to the dataset tab and select the project you want to pull data from
 3. go to the files tab and select the specific file you want to retrieve from the project.
 4. press the load data button and the R statement to pull this file from your project will be automatically inserted in your blank R script tab


![preview](https://i.imgur.com/1hEUFkd.png)


Note that data pulled __live__ from Kobo server (_rather than exported to csv or excel at point in time_) is served as `json` file. In order to get transformed to a more convenient data frame, you can use the following script: 

``` r
data <-
  hcrdata::hcrfetch(
    src = "kobo",
    dataset = "My kobo project",
    file = "data.json") %>%
  jsonlite::fromJSON() %>%
  purrr::pluck("results") %>%
  tibble::as_tibble() %>%
  purrr::set_names(~stringr::str_replace_all(., "(\\/)", "."))
```



> This package is part of `unhcrverse`, a set of packages to ease the production of statistical evidence and data stories. You can install them all with the following:

```r
## Use UNHCR Open data  - https://unhcr.github.io/unhcrdatapackage/docs/
remotes::install_github('unhcr/unhcrdatapackage’)

## API to connect to internal data source - https://unhcr-web.github.io/hcrdata/docs/
remotes::install_github('unhcr-web/hcrdata’)

## Perform High Frequency Check https://unhcr.github.io/HighFrequencyChecks/docs/
remotes::install_github('unhcr-web/HighFrequencyChecks’)

## Process data crunching for survey dataset - https://unhcr.github.io/koboloadeR/docs/
remotes::install_github('unhcr/koboloadeR’)

## Use UNHCR graphical template- https://unhcr-web.github.io/unhcRstyle/docs/
remotes::install_github('unhcr-web/unhcRstyle')
```
