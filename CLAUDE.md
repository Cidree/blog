# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal Quarto website/blog (https://adrian-cidre.com) with R content: blog posts, Udemy course pages and an R packages page. It is deployed to Netlify via GitHub Actions on every push to `main` (`.github/workflows/`, target from `_publish.yml`).

## Commands

- `quarto preview`: live preview of the whole site
- `quarto render`: full render into `_site/` (gitignored)
- `quarto render posts/<NNN_slug>/index.qmd`: render a single post. This is the only way to refresh its frozen output.
- Publishing happens in CI (`quarto publish netlify`). Don't run it locally unless asked.

## Freeze / execution model (important)

CI installs only a few R packages (dplyr, purrr, readr, shiny, downlit, xml2, rmarkdown, cranlogs), so **posts are never executed in CI**:

- `posts/_metadata.yml` sets `freeze: true`. Post outputs come from `_freeze/posts/<slug>/`, which **is committed**. After you change a post's code, re-render it locally and commit the updated `_freeze/` files, plus any new `_freeze/site_libs/` htmlwidget dependencies.
- `courses.qmd`, `packages.qmd` and `courses/_metadata.yml` set `freeze: false`. These pages are re-executed on every CI build, so any R package they use must also be installed in the workflow.
- `_quarto.yml` sets `freeze: auto` globally.

## Structure

- `posts/NNN_slug/index.qmd`: one folder per post, numbered in sequence, with `image.png` used as the listing thumbnail. Front matter: `title`, `description`, `date`, `categories`, `image`. Author, TOC, numbered sections, lightbox and utterances comments are inherited from `posts/_metadata.yml`. `posts.qmd` is the grid listing.
- `posts.qmd` renders its listing through the custom template `assets/templates/posts-listing.ejs` (featured newest post, 2-column cards, category pill bar; styles in `assets/styles/posts/posts_listing.scss`). Each item must keep `metadataAttrs(item)`, and the pill bar must keep the `.quarto-listing-category .category[data-category]` / `.quarto-listing-category-title` classes, or Quarto's filtering, sorting and pagination break. Quarto's EJS is lodash-style: the `=` tag outputs raw HTML and the `-` tag escapes (the opposite of standard EJS).
- `courses.qmd` + `courses/*.qmd`: course landing pages built from R helpers in `assets/R/courses.R`. Course metadata lives in `assets/data/courses.csv`, one row per course: title, images, `video_hours` and `lessons` (from Udemy), language, `lang` (en/es), `level` and `tagline` (both in the course's language, `` `code` `` allowed), page, reviews title pattern and **coupon URL**. `courses.qmd` is built from `courses_hero()`, `courses_offer()`, `course_cards_grid()` (language filter, cards sorted by review count) and `courses_testimonials()` (students named in `featured_testimonials`). Its stats, stars and review counts come from `udemy_reviews.csv` at render time (styles in `assets/styles/courses/courses_overview.scss`). Course pages use a shared design (styles in `assets/styles/courses/course_page.scss`; `courses/03_spatial_data_en.qmd` is the reference): `course <- course_info("<id>")`, then `course_page_hero()`, a `.course-layout` div holding `.course-aside` (`course_enroll_card(course, course_includes(course, extra))`, sticky on desktop) and `.course-main` (prose sections, `course_checklist()`, `course_curriculum(course, units)` with the `list(title, topics)` unit data, `course_reviews()`). Labels switch language with `course$lang`. Unit titles like "Unit 2a - Title (Theory)" / "Tema 2a - Título (teoría)" become a number chip and a Theory/Practice pill; topics starting with CHALLENGE/RETO or containing "Ejercicios propuestos" get a challenge flag.
  - "Update coupons" means editing `coupon_url` in `courses.csv`. The offer price and validity dates (`coupon_price`, and `coupon_start`/`coupon_end` as real `as.Date()` values) are at the top of `assets/R/courses.R`. The offer banner on `courses.qmd` only shows between those dates, so it hides itself when the coupon expires.
  - `site_root` in `courses.R` resolves paths, because course pages run from `courses/` while `courses.qmd` runs from the root.
- `packages.qmd`: package cards built by `create_packages_page()` in `assets/R/packages.R` from `assets/data/packages.csv` (package, description; `` `code` `` in descriptions becomes `<code>`). To add a package, add a row to that CSV and a logo at `assets/images/packages/<package>.png` (about 512 px). At render time it reads CRAN versions and download counts (cranlogs); a package missing from CRAN gets a "GitHub only" badge, its version from the DESCRIPTION file on GitHub, a `pak::pak()` install command and no CRAN link. Docs links assume a pkgdown site at `cidree.github.io/<package>`. Every network call falls back gracefully.
- Images live in `assets/images/{about,banners,courses,packages}/`. Images that R helpers add to a page must be `<img>` tags: Quarto only copies resources it finds there, not CSS `url()` paths in inline styles. the CV is `assets/docs/CV_AdrianCidre.pdf`. Post images stay inside each post folder.
- Styling: `assets/styles/custom_theme.scss` holds the brand palette and theme tokens (`$site-bg`, `$site-surface`, `$site-text`, `$site-heading`, `$site-link`, …) declared with `!default`, and imports `_site-base.scss`, `_site-navbar.scss` and section partials (`courses/`, `packages/`, `posts/`). Dark mode layers `_dark.scss` on top (see `_quarto.yml`) and only overrides the tokens. **Use the tokens rather than hardcoded hex colors** in components, or dark mode breaks. Never name a partial after a Bootstrap or Quarto one (`_navbar`, `_card`, `_buttons`, …): Sass resolves the theme folder first, so Bootstrap silently imports yours instead of its own.
- `assets/includes/buymeacoffee.qmd`: shared include added to pages with `{{< include >}}`.
- `_extensions/`: Quarto extensions (iconify, fontawesome, lightbox). Don't edit them by hand.

## Conventions

- R code in `.qmd` files declares dependencies with base R `use("pkg", "fn")` (R ≥ 4.4) or `library()`.
- Large data, `**/video/*` and `posts/data/` are gitignored, so videos in a `video/` folder never reach the deployed site (post 010 links to such videos). Keep committed media small: resize photos to about 1600 px and re-encode videos with ffmpeg, keeping the filename so frozen posts stay valid.
- Never rename `posts/NNN_slug/` folders or post media files: they are public URLs and frozen outputs reference them.
