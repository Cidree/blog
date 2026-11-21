
## Helpers for packages.qmd ----------------------------------------------
## Package list and descriptions: assets/data/packages.csv (one row per package).
## Logos: assets/images/packages/<package>.png
## Every network call falls back gracefully, so a CRAN/GitHub outage never
## breaks the site build.

library(shiny)

github_user <- "Cidree"

## CRAN metadata, downloaded once -----------------------------------------
cran_db <- tryCatch(
  available.packages(repos = "https://cloud.r-project.org"),
  error = function(e) NULL
)

get_cran_version <- function(package) {
  if (is.null(cran_db) || !package %in% rownames(cran_db)) return(NA_character_)
  unname(cran_db[package, "Version"])
}

## Version from the DESCRIPTION file on GitHub (for packages not on CRAN)
get_github_version <- function(package) {
  url <- sprintf(
    "https://raw.githubusercontent.com/%s/%s/HEAD/DESCRIPTION",
    github_user, package
  )
  tryCatch(
    unname(read.dcf(url(url), fields = "Version")[1, 1]),
    error = function(e) NA_character_
  )
}

## Total and last-month downloads from the RStudio CRAN mirror logs
get_downloads <- function(package) {
  total <- tryCatch(
    sum(cranlogs::cran_downloads(package, from = "2015-01-01", to = Sys.Date() - 1)$count),
    error = function(e) NA_real_
  )
  last_month <- tryCatch(
    sum(cranlogs::cran_downloads(package, when = "last-month")$count),
    error = function(e) NA_real_
  )
  list(total = total, last_month = last_month)
}

## Turn `code` in descriptions into <code> tags
format_description <- function(text) {
  text <- htmltools::htmlEscape(text)
  HTML(gsub("`([^`]+)`", "<code>\\1</code>", text))
}

fmt_number <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)


## One package card --------------------------------------------------------
create_package_card <- function(package, description, logo) {

  cran_version <- get_cran_version(package)
  on_cran      <- !is.na(cran_version)
  version      <- if (on_cran) cran_version else get_github_version(package)

  github_url  <- sprintf("https://github.com/%s/%s", github_user, package)
  website_url <- sprintf("https://%s.github.io/%s/", tolower(github_user), package)
  cran_url    <- sprintf("https://cran.r-project.org/package=%s", package)

  install_cmd <- if (on_cran) {
    sprintf('install.packages("%s")', package)
  } else {
    sprintf('pak::pak("%s/%s")', github_user, package)
  }

  ## Source + version badge
  version_badge <- span(
    class = paste("package-card__badge", if (on_cran) "is-cran" else "is-github"),
    if (on_cran) "CRAN" else "GitHub only",
    if (!is.na(version)) span(class = "package-card__badge-version", paste0("v", version))
  )

  ## Download stats (CRAN packages only)
  stats <- NULL
  if (on_cran) {
    dl <- get_downloads(package)
    if (!is.na(dl$total)) {
      stats <- div(
        class = "package-card__stats",
        span(class = "package-card__stat",
             tags$i(class = "bi bi-download"),
             strong(fmt_number(dl$total)), " downloads"),
        if (!is.na(dl$last_month)) span(
          class = "package-card__stat",
          tags$i(class = "bi bi-calendar3"),
          strong(fmt_number(dl$last_month)), " last month"
        )
      )
    }
  }

  ## Link buttons
  link_btn <- function(href, icon_class, label) {
    a(class = "package-card__link", href = href, target = "_blank", rel = "noopener",
      tags$i(class = paste("bi", icon_class)), label)
  }

  div(
    class = "package-card",

    div(
      class = "package-card__header",
      img(class = "package-card__logo", src = logo, alt = paste(package, "logo")),
      div(
        h3(package, class = "package-card__name"),
        version_badge
      )
    ),

    p(class = "package-card__description", format_description(description)),

    stats,

    div(
      class = "package-card__install",
      tags$code(install_cmd)
    ),

    div(
      class = "package-card__links",
      link_btn(website_url, "bi-book", "Docs"),
      link_btn(github_url, "bi-github", "GitHub"),
      if (on_cran) link_btn(cran_url, "bi-box-seam", "CRAN")
    )
  )
}


## Whole grid from assets/data/packages.csv ---------------------------------
create_packages_page <- function(csv = "assets/data/packages.csv",
                                 logo_dir = "assets/images/packages") {
  packages <- readr::read_csv(csv, show_col_types = FALSE)
  cards <- purrr::map2(
    packages$package, packages$description,
    \(package, description) create_package_card(
      package     = package,
      description = description,
      logo        = file.path(logo_dir, paste0(package, ".png"))
    )
  )
  div(class = "package-cards", cards)
}
