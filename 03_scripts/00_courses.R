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
      a(class = "btn btn-success btn-sm", href = href, "Learn more")
    )
  )
  
}

## Course banner -----------------------------------------------------------
course_banner <- function(price, mode, time, date, img_file) {
  
  div(
    div(
      class = "grid text-center",
      style = "vertical-align: bottom",
      div(
        class = "g-col-3",
        icon("money-bill-1-wave", class = "fa-2xl course-banner--icon"),
        p(price, class = "course-banner--text")
      ),
      div(
        class = "g-col-3",
        icon("chalkboard-user", class = "fa-2xl course-banner--icon"),
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
    ),
    
    img(src = img_file, class = "course-banner--image")
  
  )
}
