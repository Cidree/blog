
## lod packages
library(cranlogs)
library(shiny)

## function to fetch CRAN version
get_cran_version <- function(package_name) {
  tryCatch({
    available_pkgs <- available.packages(repos = "https://cran.r-project.org")
    version <- available_pkgs[package_name, "Version"]
    
    if (is.na(version)) {
      return(NULL)
    }
    
    return(version)
  }, error = function(e) {
    return(NULL)
  })
}


## create one package card
create_package_card <- function(name, 
                               description, 
                               icon_url = NULL, 
                               github_url = NULL, 
                               cran_url = NULL, 
                               badges = NULL) {
  
  ## get version
  version <- get_cran_version(name)

  ## main card str
  div(
    class = "package-card",
    
    ## header (icon + package name)
    div(
      class = "package-card-header",
      ## icon (hexticker)
      div(
        style = "margin-right: 15px;", 
        img(
          class = "package-card-header__icon",
          src   = icon_url, 
          alt   = paste(name, "logo")
        )
      ),
      ## package name + version
      div(
        h3(
          name, 
          class = "package-card-header__name"
        ),
        span(
          paste("v", version),
          class = "package-card-header__version"
        )
      )
    ),
    
    ## description
    p(
      class = "package-card-description",
      description, 
    ),
    
    ## badges section
    div(class = "package-card-badges", badges),
    
    ## links section
    div(
      class = "package-card-links",
      a(
        class = "package-card-links__link",
        href = github_url, 
        target = "_blank", 
        icon("github"), " GitHub"
      ),
      a(
        class = "package-card-links__link",
        href = cran_url, 
        target = "_blank",
        "📦 CRAN")
    )
  )
}



## function to convert data frame to packages page
create_packages_page_from_df <- function(packages_df) {
  
  ## convert each row to package card
  package_cards <- apply(packages_df, 1, function(row) {
    
    ## create badges
    total_downloads <- cranlogs::cran_downloads(row["package"], from = row["release"])
    last_month_downloads <- cranlogs::cran_downloads(row["package"], when = "last-month")
    badges_list <- list(
      ## total download badge
      img(
        class = "package-card-badges__badge",
        src   = paste0("https://img.shields.io/badge/Total%20Downloads-", sum(total_downloads$count),"-blue"),
        alt   = "Total Downloads"
      ),
      ## monthly download badge
      img(
        class = "package-card-badges__badge",
        src   = paste0("https://img.shields.io/badge/Last%20Month-", sum(last_month_downloads$count),"-green"),
        alt   = "Total Downloads"
      )
    )
    
    ## create the ith package card
    create_package_card(
      name        = row["package"],
      description = row["description"],
      icon_url    = row["hexticker"],
      github_url  = row["github_url"],
      cran_url    = row["cran_url"],
      badges      = badges_list
    )
  })
  
  ## packages grid
  div(
    class = "package-cards",
    package_cards
  )
}