
library(shiny)
suppressPackageStartupMessages(library(dplyr))

## Coupon settings -------------------------------------------------------
## Coupon URLs live in assets/data/courses.csv (one row per course).
## Price and validity period of the current offer are set here. The offer
## banner on courses.qmd only shows between coupon_start and coupon_end.
coupon_price <- "12.99€"
coupon_start <- as.Date("2026-01-10")
coupon_end   <- as.Date("2026-02-09")
coupon_active <- Sys.Date() >= coupon_start && Sys.Date() <= coupon_end

## Paths -----------------------------------------------------------------
## Quarto runs each page from its own folder: the site root is "." for
## top-level pages (courses.qmd) and ".." for pages in courses/.
site_root <- if (file.exists("_quarto.yml")) "." else ".."

courses_tbl <- readr::read_csv(
  file.path(site_root, "assets/data/courses.csv"),
  show_col_types = FALSE
)

## Get one course's metadata (a one-row list) by its id
course_info <- function(id) {
  course <- courses_tbl[courses_tbl$id == id, ]
  if (nrow(course) != 1) stop("Unknown course id: ", id)
  as.list(course)
}

## Courses overview page (courses.qmd) ---------------------------------

## Student quotes shown on courses.qmd (matched by student name in
## udemy_reviews.csv). Pick 5-star reviews from different courses.
featured_testimonials <- c(
  "John Willoughby",
  "Irving Eduardo Guerrero Castro",
  "Mariana Trinidad Ramírez Monroy"
)

## Escape text and turn `code` into <code>
fmt_inline_code <- function(x) {
  HTML(gsub("`([^`]+)`", "<code>\\1</code>", htmltools::htmlEscape(x)))
}

## All reviews, read once per page
.courses_env <- new.env()
all_reviews <- function() {
  if (is.null(.courses_env$reviews)) {
    .courses_env$reviews <- read_course_reviews(".")
  }
  .courses_env$reviews
}

## Number of reviews and average rating of every course in courses.csv
course_ratings <- function(courses = courses_tbl) {
  reviews <- all_reviews()
  purrr::map_dfr(seq_len(nrow(courses)), function(i) {
    r <- reviews$rating[grepl(courses$reviews_pattern[i], reviews$course_title)]
    tibble::tibble(
      id     = courses$id[i],
      n      = length(r),
      rating = if (length(r)) mean(r) else NA_real_
    )
  })
}

## Hero with headline and stats strip
courses_hero <- function(courses = courses_tbl) {
  reviews <- all_reviews()
  hours   <- sum(courses$video_hours, na.rm = TRUE)
  stat <- function(value, label) {
    div(class = "courses-hero__stat",
        span(class = "courses-hero__stat-value", value),
        span(class = "courses-hero__stat-label", label))
  }

  div(
    class = "courses-hero",
    # Faded photo behind the text (an <img>, so Quarto copies it to _site)
    img(class = "courses-hero__bg", alt = "", `aria-hidden` = "true",
        src = file.path(site_root, "assets/images/banners/teide.jpg")),
    div(
      class = "courses-hero__content",
      p(class = "courses-hero__eyebrow", "Online courses · R & GIS"),
      h1(class = "courses-hero__title",
         "Learn R and GIS, from your first script to real-world maps"),
      p(class = "courses-hero__lead",
        "Hands-on video courses on data analysis, spatial data, spatial ecology",
        "and reproducible workflows. Learn with real datasets, at your own pace,",
        "with lifetime access."),
      div(
        class = "courses-hero__stats",
        stat(nrow(courses), "courses"),
        stat(paste0(hours, " h"), "of video"),
        stat(nrow(reviews), "student reviews"),
        stat(paste0(format(round(mean(reviews$rating), 1), nsmall = 1), "★"),
             "average rating")
      ),
      a(class = "courses-hero__cta", href = "#courses",
        "Browse the courses", tags$i(class = "bi bi-arrow-down", `aria-hidden` = "true"))
    )
  )
}

## "Best price" callout, with the coupon offer while it is valid
courses_offer <- function() {
  div(
    class = "courses-offer",
    div(class = "courses-offer__icon",
        tags$i(class = "bi bi-tag", `aria-hidden` = "true")),
    div(
      class = "courses-offer__body",
      if (coupon_active) {
        p(class = "courses-offer__deal",
          span(class = "courses-offer__badge", "Current offer"),
          HTML(sprintf("Every course for <strong>%s</strong> until <strong>%s %d</strong>.",
                       coupon_price, format(coupon_end, "%b"),
                       as.integer(format(coupon_end, "%d")))))
      },
      p(class = "courses-offer__text",
        strong("Get the best price here. "),
        "The buttons on this page use my own coupon links: you get the same",
        "Udemy course, usually cheaper, and I receive most of the sale instead",
        "of a third. It's the best way to support new content."),
      p(class = "courses-offer__note",
        "Coupon not working? ",
        a(href = "mailto:adrian.cidre@gmail.com", "Let me know"),
        " and I'll refresh it.")
    )
  )
}

## One course card (package-card style)
course_card <- function(course, n_reviews, rating) {
  es   <- course$lang == "es"
  href <- file.path(site_root, course$page)

  div(
    class = "course-card", `data-lang` = course$lang,
    a(class = "course-card__media", href = href, tabindex = "-1",
      img(src = file.path(site_root, course$card_image), alt = course$title,
          loading = "lazy")),
    div(
      class = "course-card__body",
      div(
        class = "course-card__badges",
        span(class = paste0("course-card__badge is-", course$lang),
             tags$i(class = "bi bi-translate", `aria-hidden` = "true"),
             if (es) "ES · Español" else "EN · English"),
        span(class = "course-card__badge is-level", course$level)
      ),
      h3(class = "course-card__title no-anchor", a(href = href, course$title)),
      p(class = "course-card__tagline", fmt_inline_code(course$tagline)),
      div(
        class = "course-card__meta",
        span(tags$i(class = "bi bi-play-circle", `aria-hidden` = "true"),
             sprintf("%d h · %d %s", course$video_hours, course$lessons,
                     if (es) "lecciones" else "lessons")),
        if (n_reviews > 0) {
          span(class = "course-card__rating",
               generate_stars(round(rating * 2) / 2, class = "course-card__stars"),
               strong(format(round(rating, 1), nsmall = 1)),
               sprintf(if (es) "(%d reseñas)" else "(%d reviews)", n_reviews))
        }
      ),
      div(
        class = "course-card__links",
        a(class = "course-card__link is-primary", href = href,
          if (es) "Ver curso" else "See course",
          tags$i(class = "bi bi-arrow-right", `aria-hidden` = "true")),
        a(class = "course-card__link", href = course$coupon_url,
          target = "_blank", rel = "noopener",
          "Udemy", tags$i(class = "bi bi-box-arrow-up-right", `aria-hidden` = "true"))
      )
    )
  )
}

## Language filter + grid with one card per course (most reviewed first)
course_cards_grid <- function(courses = courses_tbl) {
  courses <- courses |>
    left_join(course_ratings(courses), by = "id") |>
    arrange(desc(n))

  pill <- function(lang, label, count, active = FALSE) {
    tags$button(
      type = "button", `data-lang` = lang,
      class = paste("courses-filter__pill", if (active) "active"),
      label, span(class = "courses-filter__count", count)
    )
  }

  tagList(
    div(
      class = "courses-filter", role = "toolbar",
      `aria-label` = "Filter courses by language",
      pill("all", "All", nrow(courses), active = TRUE),
      pill("en", "English", sum(courses$lang == "en")),
      pill("es", "Español", sum(courses$lang == "es"))
    ),
    div(
      class = "course-cards",
      purrr::map(seq_len(nrow(courses)), function(i) {
        course_card(as.list(courses[i, ]), courses$n[i], courses$rating[i])
      })
    ),
    tags$script(HTML("
      document.addEventListener('click', function (e) {
        const pill = e.target.closest('.courses-filter__pill');
        if (!pill) return;
        const lang = pill.dataset.lang;
        document.querySelectorAll('.courses-filter__pill').forEach(function (p) {
          p.classList.toggle('active', p === pill);
        });
        document.querySelectorAll('.course-card').forEach(function (card) {
          card.hidden = lang !== 'all' && card.dataset.lang !== lang;
        });
      });
    "))
  )
}

## Student quotes (featured_testimonials)
courses_testimonials <- function(names = featured_testimonials) {
  reviews <- all_reviews() |>
    filter(student_name %in% names, !is.na(review_text)) |>
    distinct(student_name, .keep_all = TRUE)
  reviews <- reviews[order(match(reviews$student_name, names)), ]

  div(
    class = "courses-testimonials",
    purrr::map(seq_len(nrow(reviews)), function(i) {
      r <- reviews[i, ]
      tags$figure(
        class = "testimonial",
        generate_stars(r$rating, class = "testimonial__stars"),
        tags$blockquote(class = "testimonial__quote", r$review_text),
        tags$figcaption(
          class = "testimonial__author",
          span(class = "testimonial__avatar", substr(r$student_name, 1, 1)),
          div(
            span(class = "testimonial__name", r$student_name),
            span(class = "testimonial__course", sub(" \\[.*\\]$", "", r$course_title))
          )
        )
      )
    })
  )
}

## Floating Enroll button (shown on narrow screens) ---------------------
create_course_button <- function(enrollment_url = "#", 
                                 button_text = "Enroll Now", 
                                 trigger_height = 300) {

  
  # Create the button HTML
  button_html <- div(
    class = "enrollment-button-container",
    tags$a(
      href = enrollment_url,
      class = "enrollment-btn",
      onclick = "handleEnrollment(event)",
      tags$svg(
        class = "btn-icon",
        viewBox = "0 0 24 24",
        tags$path(d = "M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z")
      ),
      button_text
    )
  )
  
  # Create JavaScript
  js_script <- tags$script(HTML(sprintf("
    function handleEnrollment(event) {
      event.preventDefault();
      
      // Add pulse effect
      const button = event.currentTarget;
      button.classList.add('pulse');
      
      // Remove pulse effect after animation
      setTimeout(() => {
        button.classList.remove('pulse');
      }, 600);
      
      // Open enrollment URL
      if ('%s' !== '#') {
        window.open('%s', '_blank');
      } else {
        alert('Please set your enrollment URL in the function parameters');
      }
    }

    // Show button after scrolling down
    window.addEventListener('scroll', function() {
      const button = document.querySelector('.enrollment-button-container');
      const scrollPosition = window.scrollY;
      const triggerHeight = %d;
      
      if (scrollPosition > triggerHeight) {
        button.classList.add('show');
      } else {
        button.classList.remove('show');
      }
    });
  ", enrollment_url, enrollment_url, trigger_height)))
  
  # Return the complete HTML widget
  tagList(button_html, js_script)
}



## Reviews -------

## Read the Udemy reviews of one course (matched by a pattern on its title)
read_course_reviews <- function(pattern) {
  reviews <- readr::read_csv(
    file.path(site_root, "assets/data/udemy_reviews.csv"),
    show_col_types = FALSE
  )
  names(reviews) <- c("course_title", "student_name", "date_created", "rating", "review_text")
  reviews |>
    filter(grepl(pattern, course_title)) |>
    mutate(date_created = as.Date(date_created))
}

## function to generate star rating HTML
generate_stars <- function(rating, max_stars = 5, class = "star-rating") {
  stars <- character(max_stars)
  for (i in 1:max_stars) {
    if (i <= rating) {
      stars[i] <- "★"
    } else if (rating >= i - .5) {
      stars[i] <- "⯪"
    } else {
      stars[i] <- "☆"
    }
  }
  span(class = class, paste(stars, collapse = ""))
}

## Course pages (courses/*.qmd) -------------------------------------------
## Shared design for every course page. Labels follow course$lang.

tr <- function(course, en, es) if (identical(course$lang, "es")) es else en

bi <- function(name) tags$i(class = paste0("bi bi-", name), `aria-hidden` = "true")

## Rating summary of one course (n, rating, reviews table)
course_review_data <- function(course) {
  reviews <- all_reviews() |>
    filter(grepl(course$reviews_pattern, course_title))
  list(
    reviews = reviews,
    n       = nrow(reviews),
    rating  = if (nrow(reviews)) mean(reviews$rating) else NA_real_
  )
}

## Hero: badges, title, tagline, rating, author
course_page_hero <- function(course) {
  rv <- course_review_data(course)
  div(
    class = "course-hero",
    img(class = "course-hero__bg", alt = "", `aria-hidden` = "true",
        src = file.path(site_root, course$banner_image)),
    div(
      class = "course-hero__content",
      div(
        class = "course-card__badges",
        span(class = paste0("course-card__badge is-", course$lang), bi("translate"),
             tr(course, "EN · English", "ES · Español")),
        span(class = "course-card__badge is-level", course$level)
      ),
      h1(class = "course-hero__title", course$title),
      p(class = "course-hero__tagline", fmt_inline_code(course$tagline)),
      div(
        class = "course-hero__meta",
        if (rv$n > 0) {
          a(class = "course-hero__rating", href = "#reviews",
            strong(format(round(rv$rating, 1), nsmall = 1)),
            generate_stars(round(rv$rating * 2) / 2, class = "course-card__stars"),
            span(sprintf(tr(course, "(%d reviews)", "(%d reseñas)"), rv$n)))
        },
        span(bi("play-circle"),
             sprintf(tr(course, "%d h of video", "%d h de vídeo"), course$video_hours)),
        span(bi("person"), tr(course, "Created by ", "Creado por "),
             a(href = file.path(site_root, "about.qmd"), "Adrián Cidre"))
      )
    )
  )
}

## Sticky enroll card: cover, price, button, what's included
course_enroll_card <- function(course, includes) {
  div(
    class = "course-enroll",
    img(class = "course-enroll__cover", src = file.path(site_root, course$card_image),
        alt = course$title),
    div(
      class = "course-enroll__body",
      if (coupon_active) {
        p(class = "course-enroll__price",
          span(class = "course-enroll__amount", coupon_price),
          span(class = "courses-offer__badge",
               tr(course, "Coupon price", "Precio con cupón")))
      } else {
        p(class = "course-enroll__price is-plain",
          tr(course, "Best price through this link", "El mejor precio con este enlace"))
      },
      a(class = "course-enroll__btn", href = course$coupon_url,
        target = "_blank", rel = "noopener",
        tr(course, "Enroll on Udemy", "Inscríbete en Udemy"), bi("box-arrow-up-right")),
      p(class = "course-enroll__note",
        tr(course, "Lifetime access · learn at your own pace",
                   "Acceso de por vida · aprende a tu ritmo")),
      h3(class = "course-enroll__heading no-anchor",
         tr(course, "This course includes", "Este curso incluye")),
      tags$ul(
        class = "course-enroll__includes",
        purrr::map(includes, function(x) tags$li(bi(x[[1]]), x[[2]]))
      )
    )
  )
}

## Default "includes" list built from courses.csv; extra items go at the end
course_includes <- function(course, extra = list()) {
  c(
    list(
      list("play-circle", sprintf(tr(course, "%d hours of video", "%d horas de vídeo"),
                                  course$video_hours)),
      list("collection-play", sprintf(tr(course, "%d lessons", "%d lecciones"),
                                      course$lessons)),
      list("folder2-open", tr(course, "All the course materials",
                                      "Todo el material del curso"))
    ),
    extra,
    list(
      list("infinity", tr(course, "Lifetime access", "Acceso de por vida")),
      list("chat-dots", tr(course, "Q&A with the instructor",
                                   "Resolución de dudas con el profesor"))
    )
  )
}

## Checklist ("What you'll learn", "Requirements")
course_checklist <- function(items, columns = 2) {
  tags$ul(
    class = paste0("course-checklist cols-", columns),
    purrr::map(items, function(x) tags$li(bi("check-circle-fill"), span(fmt_inline_code(x))))
  )
}

## Curriculum: one <details> card per unit (same list(title, topics) data
## the pages always used). "(Theory)/(Practice)" in a title becomes a pill.
course_curriculum <- function(course, units) {
  kind_of <- function(title) {
    if (grepl("\\((Theory|Teoría)\\)", title, ignore.case = TRUE)) "theory"
    else if (grepl("\\((Practice|Práctica)\\)", title, ignore.case = TRUE)) "practice"
    else NA_character_
  }
  div(
    class = "course-curriculum",
    div(
      class = "course-curriculum__bar",
      span(sprintf(tr(course, "%d units · %d lessons · %d h of video",
                              "%d unidades · %d lecciones · %d h de vídeo"),
                   length(units), course$lessons, course$video_hours)),
      tags$button(type = "button", class = "course-curriculum__toggle",
                  `data-open` = tr(course, "Expand all", "Desplegar todo"),
                  `data-close` = tr(course, "Collapse all", "Plegar todo"),
                  tr(course, "Expand all", "Desplegar todo"))
    ),
    purrr::imap(units, function(unit, i) {
      kind  <- kind_of(unit$title)
      title <- trimws(gsub("\\s*\\((Theory|Practice|Teoría|Práctica)\\)", "", unit$title,
                           ignore.case = TRUE))
      # "Unit 2a - Spatial Data" -> number chip "2a" + "Spatial Data"
      prefix <- "^(Unit|Unidad|Tema|Módulo|Bloque)\\s+(\\w+)\\s*[-–:]\\s*"
      if (grepl(prefix, title)) {
        num   <- sub("^0+(\\d)", "\\1", sub(paste0(prefix, ".*$"), "\\2", title))
        title <- sub(prefix, "", title)
      } else {
        num <- NULL
      }
      tags$details(
        class = "course-unit", open = if (i == 1) NA,
        tags$summary(
          if (!is.null(num)) span(class = "course-unit__num", num),
          span(class = "course-unit__title", title),
          if (!is.na(kind)) {
            span(class = paste0("course-unit__kind is-", kind),
                 switch(kind,
                        theory   = tr(course, "Theory", "Teoría"),
                        practice = tr(course, "Practice", "Práctica")))
          },
          span(class = "course-unit__count",
               sprintf(tr(course, "%d topics", "%d temas"), length(unit$topics))),
          bi("chevron-down")
        ),
        tags$ul(
          class = "course-unit__topics",
          purrr::map(unit$topics, function(topic) {
            challenge <- grepl("^CHALLENGE|^RETO|Ejercicios propuestos|proposed exercises",
                               topic)
            tags$li(
              class = if (challenge) "is-challenge",
              if (challenge) bi("flag-fill") else bi("dot"),
              topic
            )
          })
        )
      )
    }),
    tags$script(HTML("
      document.addEventListener('click', function (e) {
        const btn = e.target.closest('.course-curriculum__toggle');
        if (!btn) return;
        const units = btn.closest('.course-curriculum').querySelectorAll('.course-unit');
        const open = [...units].some(u => !u.open);
        units.forEach(u => u.open = open);
        btn.textContent = open ? btn.dataset.close : btn.dataset.open;
      });
    "))
  )
}

## Reviews: summary with distribution + review cards (first 6 visible)
course_reviews <- function(course, visible = 6) {
  rv <- course_review_data(course)
  if (rv$n == 0) return(NULL)

  stars_int <- pmin(5, pmax(1, floor(rv$reviews$rating + .5)))
  dist <- purrr::map(5:1, function(k) {
    n   <- sum(stars_int == k)
    pct <- round(100 * n / rv$n)
    div(class = "review-summary__row",
        span(class = "review-summary__label", paste0(k, "★")),
        div(class = "review-summary__bar",
            span(style = sprintf("width: %d%%;", pct))),
        span(class = "review-summary__pct", paste0(pct, "%")))
  })

  with_text <- rv$reviews |>
    filter(!is.na(review_text), nzchar(trimws(review_text))) |>
    arrange(desc(date_created))

  cards <- purrr::map(seq_len(nrow(with_text)), function(i) {
    r <- with_text[i, ]
    tags$figure(
      class = "testimonial", hidden = if (i > visible) NA,
      div(class = "testimonial__top",
          generate_stars(r$rating, class = "testimonial__stars"),
          span(class = "testimonial__date", format(r$date_created, "%b %Y"))),
      tags$blockquote(class = "testimonial__quote", r$review_text),
      tags$figcaption(
        class = "testimonial__author",
        span(class = "testimonial__avatar", substr(r$student_name, 1, 1)),
        span(class = "testimonial__name", r$student_name)
      )
    )
  })

  div(
    class = "course-reviews",
    div(
      class = "review-summary",
      div(class = "review-summary__score",
          span(class = "review-summary__value", format(round(rv$rating, 1), nsmall = 1)),
          generate_stars(round(rv$rating * 2) / 2, class = "course-card__stars"),
          span(class = "review-summary__count",
               sprintf(tr(course, "%d ratings on Udemy", "%d valoraciones en Udemy"), rv$n))),
      div(class = "review-summary__dist", dist)
    ),
    p(class = "course-reviews__note",
      if (nrow(with_text) > 0) {
        tr(course, "Every review with a comment is shown here, positive or negative.",
                   "Aquí aparecen todas las reseñas con comentario, positivas y negativas.")
      } else {
        tr(course, "No written reviews yet: these are the star ratings students gave on Udemy.",
                   "Aún no hay reseñas escritas: estas son las valoraciones que los estudiantes han dado en Udemy.")
      }),
    div(class = "course-reviews__grid", cards),
    if (nrow(with_text) > visible) {
      tagList(
        tags$button(type = "button", class = "course-reviews__more",
                    sprintf(tr(course, "Show all %d reviews", "Ver las %d reseñas"),
                            nrow(with_text))),
        tags$script(HTML("
          document.addEventListener('click', function (e) {
            const btn = e.target.closest('.course-reviews__more');
            if (!btn) return;
            btn.closest('.course-reviews').querySelectorAll('.testimonial[hidden]')
              .forEach(c => c.hidden = false);
            btn.remove();
          });
        "))
      )
    }
  )
}
