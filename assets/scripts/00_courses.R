
library(shiny)
suppressPackageStartupMessages(library(dplyr))

## Coupons
spatial_ecology_coupon <- "https://www.udemy.com/course/ecologia-espacial-aplicada-con-r/?couponCode=B7BDA6A70A6F2E3172FD"
mastering_r_coupon     <- "https://www.udemy.com/course/mastering-r-best-practices-and-essential-tools/?couponCode=FACCB973BF5A29D4F151"
gis_spanish_coupon     <- "https://www.udemy.com/course/introduccion-a-analisis-de-datos-espaciales-en-r/?couponCode=9AD6666576BA0C77E969"
gis_english_coupon     <- "https://www.udemy.com/course/introduction-to-spatial-data-analysis-and-gis-in-r/?couponCode=8EBCFF6A3D95237652CF"
quarto_coupon          <- "https://www.udemy.com/course/quarto-diseno-de-documentos-profesionales-en-rstudio/?couponCode=6A96BBB51A7737E1CD3A"
data_analysis_coupon   <- "https://www.udemy.com/course/introduccion-a-analisis-y-visualizacion-de-datos-en-r-2023/?couponCode=84D9F587611D923EDA7C"
coupon_price           <- "12.99€"

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
        # tags$li(class = "list-group-item", icon("calendar-days"), date),
        tags$li(class = "list-group-item", icon("clock"), time),
        tags$li(class = "list-group-item", icon("language"), language)
      ),
      a(class = "btn btn-success btn-sm card-course-btn", href = href, "Learn more")
    )
  )
}



## Course banner -----------------------------------------------------------
create_banner <- function(title, text, background_image = "../assets/figures/teide.JPG",
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
          h2(title, class = "text-black banner-title")
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
                               title = "Course Rating", size = "1.5em", num_reviews = NULL) {
  
  stars <- generate_stars(rating, max_stars, class = "course-stars")
  
  # Create the rating section
  rating_section <- div(
    class = "course-rating",
    style = "display: inline-block; margin: 20px 0; padding: 15px; border: 1px solid #e0e0e0; border-radius: 8px; background-color: #f9f9f9;",
    
    h4(title, style = "margin: 0 0 10px 0; color: #333;"),
    
    div(
      class = "stars-container",
      style = "align-items: center; gap: 2px;",
      stars,
      if (show_numeric) {
        numeric_text <- paste0(" ", format(rating, nsmall = 1), "/", max_stars)
        if (!is.null(num_reviews)) {
          numeric_text <- paste0(numeric_text, " (", num_reviews, " reviews)")
        }
        span(
          numeric_text,
          style = "margin-left: 8px; color: #666; font-size: 0.9em;"
        )
      }
    )
  )
  
  return(rating_section)
}



##  Current offer card ----------
offer_card <- div(
  class = "offer-card",
  
  # Urgency badge
  div(
    class = "urgency-badge",
    tags$i(class = "fas fa-fire"),
    " Limited Time"
  ),
  
  # Header section
  div(
    class = "offer-header",
    h2("Current Offer", class = "offer-title"),
    div(
      class = "clock-icon",
      tags$i(class = "fas fa-clock")
    )
  ),
  
  # Price section
  div(
    class = "price-section",
    div("12.99€", class = "price"),
    div("Special Price", class = "price-label")
  ),
  
  # Date section
  div(
    class = "date-section",
    p(
      class = "date-text",
      tags$i(class = "fas fa-calendar-alt text-primary me-2"),
      "Valid Period"
    ),
    p(
      class = "date-range",
      tags$i(class = "fas fa-play text-success"),
      tags$span("Jan 10th"),
      tags$i(class = "fas fa-arrow-right text-muted"),
      tags$span("Feb 9th"),
      tags$i(class = "fas fa-stop text-danger")
    )
  )
)
