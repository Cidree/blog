library(shiny)

## Card for courses.qmd -------------------------------------------------
course_card <- function(file, course_title, mode, date, time, language, href) {
  
  div(
    class = "card card-course text-center p-1",
    div(
      class = "card-img--container",
      img(class = "img-circle card-img--text", src = file)
    ),
    div(
      class = "card-body",
      div(
        class = "card-course-title--container",
        h5(course_title, class = "card-course--title")
      ),
      p(mode, class = "card-course-mode"),
      tags$ul(
        class = "list-group list-group-flush",
        tags$li(class = "list-group-item", icon("calendar-days"), date),
        tags$li(class = "list-group-item", icon("clock"), time),
        tags$li(class = "list-group-item", icon("language"), language)
      ),
      a(class = "btn btn-success btn-sm card-course-btn", href = href, "Learn more")
    )
  )
}

## Course banner -----------------------------------------------------------
course_banner <- function(price, mode, time, date, img_file, lang = "es") {
  
  div(
    img(src = img_file, class = "course-banner--image"),
    ## Icons
    div(
      class = "grid text-center",
      style = "vertical-align: bottom",
      div(
        class = "g-col-3",
        icon("euro-sign", class = "fa-2xl course-banner--icon")
      ),
      div(
        class = "g-col-3",
        icon("chalkboard-user", class = "fa-2xl course-banner--icon")
      ),
      div(
        class = "g-col-3",
        icon("clock", class = "fa-2xl course-banner--icon")
      ),
      div(
        class = "g-col-3",
        icon("calendar-days", class = "fa-2xl course-banner--icon")
      )
    ),
    ## Titles
    div(
      class = "grid text-center",
      div(
        class = "g-col-3",
        p(if (lang == "es") "Precio" else "Price", class = "course-banner--title")
      ),
      div(
        class = "g-col-3",
        p(if (lang == "es") "Modalidad" else "Mode", class = "course-banner--title")
      ),
      div(
        class = "g-col-3",
        p(if (lang == "es") "Duración" else "Time", class = "course-banner--title")
      ),
      div(
        class = "g-col-3",
        p(if (lang == "es") "Fecha" else "Date", class = "course-banner--title")
      )
    ),
    ## Characteristics
    div(
      class = "grid text-center",
      div(
        class = "g-col-3",
        p(price, class = "course-banner--text")
      ),
      div(
        class = "g-col-3",
        p(mode, class = "course-banner--text")
      ),
      div(
        class = "g-col-3",
        p(time, class = "course-banner--text")
      ),
      div(
        class = "g-col-3",
        p(date, class = "course-banner--text")
      )
    )
    
    
  
  )
}

## Course block ---------------------------------------------------------
course_block <- function(section_name, id_accordion, id_heading, id_collapse, ...) {
  
  div(
    class = "accordion",
    id = id_accordion,
    div(
      class = "accordion-item",
      h2(
        class = "accordion-header text-center",
        id = id_heading,
        tags$button(
          class = "accordion-button accordion-header--course",
          type = "button",
          `data-bs-toggle` = "collapse",
          `data-bs-target` = stringr::str_glue("#{id_collapse}"),
          `aria-expanded` = "true",
          `aria-controls` = id_collapse,
          section_name
        )
      ),
      tags$div(
        id = id_collapse,
        class = "accordion-collapse collapse accordion-collapse--course",
        `aria-labelledby` = id_heading,
        `data-bs-parent` = stringr::str_glue("#{id_accordion}"),
        tags$div(
          class = "accordion-body",
          ...
        )
      )
    )
  )
  
  
}
