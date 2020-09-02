ui <- miniUI::miniPage(
  shinyjs::useShinyjs(),
  miniUI::gadgetTitleBar(
    "UNHCR Data Browser",
    left = shiny::actionButton("refresh", NULL, icon = shiny::icon("refresh")),
    right = shiny::actionButton("done", "Done", NULL, class = "btn-primary")),
  miniUI::miniTabstripPanel(
    miniUI::miniTabPanel("Sources", icon = shiny::icon("archive"),
                         miniUI::miniContentPanel(
                           shiny::radioButtons("src", label = NULL,
                                               choices = c("Loading..." = "")))),
    miniUI::miniTabPanel("Datasets", icon = shiny::icon("folder"),
                         miniUI::miniContentPanel(
                           shiny::radioButtons("dataset", label = NULL,
                                               choices = c("Please choose a datasource first" = "")))),
    miniUI::miniTabPanel("Files", icon = shiny::icon("file"),
                         miniUI::miniContentPanel(
                           shiny::radioButtons("file", label = NULL,
                                               choices = c("Please choose a dataset first" = "")))),
    id = "tab"),
  miniUI::miniButtonBlock(shiny::actionButton("load", "Load data", class = "btn-primary")))

server <- function(input, output, session) {
  idx <- hcrindex()

  shiny::updateRadioButtons(session, "src",
                            choices =
                              dplyr::distinct(idx, srcname, srcdesc) %>%
                              { purrr::set_names(.$srcname, .$srcdesc) })

  shiny::observe({
    if (input$src != "") {
      shiny::updateRadioButtons(session, "dataset",
                                choices = c("Please choose a datasource first" = ""))
      shiny::updateRadioButtons(session, "file",
                                choices = c("Please choose a dataset first" = ""))
    }
  })

  shiny::observe({
    if (input$tab == "Datasets" && input$src != "") {
      shiny::updateRadioButtons(session, "dataset",
                                choices =
                                  dplyr::filter(idx, srcname == input$src) %>%
                                  dplyr::distinct(dsname, dsdesc) %>%
                                  dplyr::arrange(dsdesc) %>%
                                  { purrr::set_names(.$dsname, .$dsdesc)} )
      shiny::updateRadioButtons(session, "file",
                                choices = c("Please choose a dataset first" = ""))
    }
  })

  shiny::observe({
    if (input$tab == "Files" && input$src != "" && input$dataset != "") {
      shiny::updateRadioButtons(session, "file",
                                choices =
                                  dplyr::filter(idx, srcname == input$src, dsname == input$dataset) %>%
                                  dplyr::arrange(filedesc) %>%
                                  { purrr::set_names(.$filename, .$filedesc)} )
    }
  })

  shiny::observe({
    shinyjs::toggleState("load", input$tab == "Files")
  })

  shiny::observeEvent(input$load, {
    rstudioapi::insertText(
      glue::glue(
        'hcrdata::hcrfetch(src = "{input$src}",',
        'dataset = "{input$dataset}",',
        'file = "{input$file}")',
        .sep = " "))
  })

  shiny::observeEvent(input$refresh, {
    idx <- hcrindex(FALSE)
    shiny::updateTabsetPanel(session, "tab", "Sources")
  })

  shiny::observeEvent(input$done, {
    shiny::stopApp(TRUE)
  })
}

#' @export
hcrbrowse <- function() {
  shiny::runGadget(shiny::shinyApp(ui, server), viewer = shiny::paneViewer())
}
