# `hcrdata`
An RStudio addin that wraps access to UNHCR data behind a uniform interface.

Currently supported data sources:
* KoBoToolbox
* Raw Internal Data Library
* Microdata Library

With more to come (_popstats, rsq, etc..._).

# Usage
The package expects to find your API keys / access credentials in environment variables. The easiest way to get them there and persist your settings is to store them in your `.Renviron` file which is automatically read by R on startup. You can access the file by calling `usethis::edit_r_environ()` (assuming you have the `usethis` package installed) and entering:

    KOBO_API_KEY=xxxxxxxxx
    RIDL_API_KEY=xxxxxxxxx
    MDL_ACCESS_CREDS=user:password

Once that's done, restart your R session to make sure that the variables are loaded.

You should then be able to launch the "data browser" from the addins menu.

![preview](https://i.imgur.com/0ItFWcz.png)
