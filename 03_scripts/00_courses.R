library(shiny)

## Card for courses.qmd -------------------------------------------------
course_card <- function(file, course_title, mode, date, time, language, href) {
  
  div(
    class = "card card-course text-center p-1",
    img(class = "img-circle card-img-top", src = file),
    div(
      class = "card-body",
      h5(course_title, class = "card-course-title"),
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
course_banner <- function(price, mode, time, date, img_file) {
  
  div(
    img(src = img_file, class = "course-banner--image"),
    div(
      class = "grid text-center",
      style = "vertical-align: bottom",
      div(
        class = "g-col-3",
        icon("money-bill-1", class = "fa-2xl course-banner--icon"),
        p(price, class = "course-banner--text")
      ),
      div(
        class = "g-col-3",
        icon("education",lib = "glyphicon", class = "fa-2xl course-banner--icon"),
        p(mode, class = "course-banner--text")
      ),
      div(
        class = "g-col-3",
        icon("clock", class = "fa-2xl course-banner--icon"),
        p(time, class = "course-banner--text")
      ),
      div(
        class = "g-col-3",
        icon("calendar-days", class = "fa-2xl course-banner--icon"),
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
