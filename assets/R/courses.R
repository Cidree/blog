
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
  hours   <- sum(as.numeric(sub("\\D.*$", "", courses$hours)), na.rm = TRUE)
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
        span(tags$i(class = "bi bi-clock", `aria-hidden` = "true"), course$hours),
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

## Course banner -----------------------------------------------------------
create_banner <- function(title, text, background_image = file.path(site_root, "assets/images/banners/teide.jpg"),
                             price, mode, time, date, lang) {
  # Create the banner structure
  div(
    class = "column-screen banner d-none d-sm-block",
    
    # Background image section with text overlay
    div(
      class = "banner-hero",
      div(
        class = "banner-container",
        div(
          h2(title, class = "banner-title")
        ),
        # Text section
        div(
          class = "banner-text",
          text
        )
      )
    ),
    
    # Course info section (below the image)
    div(
      class = "course-info-section",
      div(
        class = "grid text-center",
        div(
          class = "g-col-3 course-info-item",
          icon("euro-sign", class = "fa-2xl course-banner--icon"),
          p(if (lang == "es") "Precio" else "Price", class = "course-banner--title"),
          p(price, class = "course-banner--text")
        ),
        div(
          class = "g-col-3 course-info-item",
          icon("chalkboard-user", class = "fa-2xl course-banner--icon"),
          p(if (lang == "es") "Modalidad" else "Mode", class = "course-banner--title"),
          p(mode, class = "course-banner--text")
        ),
        div(
          class = "g-col-3 course-info-item",
          icon("clock", class = "fa-2xl course-banner--icon"),
          p(if (lang == "es") "Duración" else "Time", class = "course-banner--title"),
          p(time, class = "course-banner--text")
        ),
        div(
          class = "g-col-3 course-info-item",
          icon("calendar-days", class = "fa-2xl course-banner--icon"),
          p(if (lang == "es") "Fecha" else "Date", class = "course-banner--title"),
          p(date, class = "course-banner--text")
        )
      )
    ),
    
    # Add inline CSS styles
    tags$style(HTML(paste0("
      .banner-hero::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-image: url('", background_image, "');
        background-size: cover;
        background-position: center;
        opacity: 0.2;
        z-index: 0;
      }
    ")))
  )
}


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



## Function to create a course structure block
create_course_structure <- function(course_title, lessons) {
  
  # Create lesson items
  lesson_items <- purrr::map(lessons, function(lesson) {
    # Create topic list for each lesson
    topic_list <- if (length(lesson$topics) > 0) {
      tags$ul(
        class = "topic-list",
        purrr::map(lesson$topics, function(topic) {
          tags$li(class = "topic-item", topic)
        })
      )
    } else {
      NULL
    }
    
    # Create lesson container
    tags$div(
      class = "lesson-container",
      tags$div(
        class = "lesson-header",
        tags$h3(class = "lesson-title", lesson$title),
        if (!is.null(topic_list)) {
          tags$button(
            class = "toggle-btn",
            type = "button",
            onclick = "toggleTopics(this)",
            "▼"
          )
        }
      ),
      if (!is.null(topic_list)) {
        tags$div(class = "topics-container", topic_list)
      }
    )
  })
  
  # Main course structure
  tags$div(
    class = "course-structure",
    tags$h2(class = "course-title", course_title),
    tags$div(class = "lessons-container", lesson_items),
    
    # Add JavaScript for toggle functionality
    tags$script(HTML("
      function toggleTopics(button) {
        const container = button.closest('.lesson-container').querySelector('.topics-container');
        const isCollapsed = container.classList.contains('collapsed');
        
        if (isCollapsed) {
          container.classList.remove('collapsed');
          button.textContent = '▼';
        } else {
          container.classList.add('collapsed');
          button.textContent = '▶';
        }
      }
      
      // Initialize all topics as expanded
      document.addEventListener('DOMContentLoaded', function() {
        const allContainers = document.querySelectorAll('.topics-container');
        allContainers.forEach(container => {
          // Start collapsed for cleaner initial view
          container.classList.add('collapsed');
        });
        
        const allButtons = document.querySelectorAll('.toggle-btn');
        allButtons.forEach(button => {
          button.textContent = '▶';
        });
      });
    "))
  )
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

## function to create a single review card
create_review_card <- function(student_name, course_title, rating, review_text, date_created) {
  div(
    class = "review-card",
    div(
      class = "review-header",
      div(
        class = "student-info",
        div(
          class = "student-avatar",
          substr(student_name, 1, 1)  # First letter of name
        ),
        div(
          class = "student-details",
          h4(class = "student-name", student_name),
          p(class = "course-name", "")
        )
      ),
      div(
        class = "review-meta",
        generate_stars(rating),
        p(class = "review-date", format(as.Date(date_created), "%B %Y"))
      )
    ),
    div(
      class = "review-content",
      p(class = "review-text", review_text)
    )
  )
}

# Function to create the reviews section with horizontal carousel
create_reviews_section <- function(reviews_df) {
  
  # Create individual review cards
  review_cards <- purrr::map(1:nrow(reviews_df), function(i) {
    create_review_card(
      student_name = reviews_df$student_name[i],
      course_title = reviews_df$course_title[i],
      rating = reviews_df$rating[i],
      review_text = reviews_df$review_text[i],
      date_created = reviews_df$date_created[i]
    )
  })
  
  # JavaScript for carousel functionality
  js_script <- tags$script(HTML("
    document.addEventListener('DOMContentLoaded', function() {
      const carousel = document.querySelector('.reviews-carousel');
      const prevBtn = document.querySelector('.carousel-nav.prev');
      const nextBtn = document.querySelector('.carousel-nav.next');
      
      if (!carousel || !prevBtn || !nextBtn) return;
      
      const cardWidth = 350 + 32; // card width + gap
      let currentScroll = 0;
      const maxScroll = carousel.scrollWidth - carousel.clientWidth;
      
      function updateButtons() {
        prevBtn.classList.toggle('disabled', currentScroll <= 0);
        nextBtn.classList.toggle('disabled', currentScroll >= maxScroll);
      }
      
      function scrollToPosition(position) {
        carousel.scrollTo({
          left: position,
          behavior: 'smooth'
        });
        currentScroll = position;
        updateButtons();
      }
      
      prevBtn.addEventListener('click', function() {
        if (currentScroll > 0) {
          const newPosition = Math.max(0, currentScroll - cardWidth);
          scrollToPosition(newPosition);
        }
      });
      
      nextBtn.addEventListener('click', function() {
        if (currentScroll < maxScroll) {
          const newPosition = Math.min(maxScroll, currentScroll + cardWidth);
          scrollToPosition(newPosition);
        }
      });
      
      // Initialize button states
      updateButtons();
      
      // Update on window resize
      window.addEventListener('resize', function() {
        const newMaxScroll = carousel.scrollWidth - carousel.clientWidth;
        if (newMaxScroll !== maxScroll) {
          maxScroll = newMaxScroll;
          currentScroll = carousel.scrollLeft;
          updateButtons();
        }
      });
      
      // Track scroll position when user scrolls manually
      carousel.addEventListener('scroll', function() {
        currentScroll = carousel.scrollLeft;
        updateButtons();
      });
    });
  "))
  
  # Complete reviews section with carousel
  div(
    class = "reviews-section",
    js_script,
    div(
      class = "reviews-carousel-container",
      # Previous button
      div(
        class = "carousel-nav prev",
        onclick = "void(0);",
        HTML('<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>')
      ),
      # Next button  
      div(
        class = "carousel-nav next",
        onclick = "void(0);",
        HTML('<svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>')
      ),
      # Carousel container
      div(
        class = "reviews-carousel",
        review_cards
      )
    )
  )
}



## Overall rating ----------------------
create_star_rating <- function(rating, max_stars = 5, show_numeric = TRUE,
                               title = "Course Rating", num_reviews = NULL) {

  stars <- generate_stars(rating, max_stars, class = "course-stars")

  div(
    class = "course-rating",
    h4(title, class = "course-rating--title"),
    div(
      class = "stars-container",
      stars,
      if (show_numeric) {
        numeric_text <- paste0(" ", format(rating, nsmall = 1), "/", max_stars)
        if (!is.null(num_reviews)) {
          numeric_text <- paste0(numeric_text, " (", num_reviews, " reviews)")
        }
        span(numeric_text, class = "course-rating--numeric")
      }
    )
  )
}
