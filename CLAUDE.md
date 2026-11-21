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
- `courses.qmd` + `courses/*.qmd`: course landing pages built from R helpers in `assets/R/courses.R`. Course metadata lives in `assets/data/courses.csv`, one row per course: title, images, hours, language, page, reviews title pattern and **coupon URL**. `courses.qmd` renders every row with `course_cards_grid()`. Each course page calls `course <- course_info("<id>")` and `read_course_reviews(course$reviews_pattern)`, which reads `assets/data/udemy_reviews.csv`.
  - "Update coupons" means editing `coupon_url` in `courses.csv`. The offer price and validity dates (`coupon_price`, `coupon_start`, `coupon_end`) are at the top of `assets/R/courses.R`.
  - `site_root` in `courses.R` resolves paths, because course pages run from `courses/` while `courses.qmd` runs from the root.
- `packages.qmd`: package cards built by `assets/R/packages.R`. It fetches live CRAN versions and download counts (cranlogs) at render time.
- Images live in `assets/images/{about,banners,courses,packages}/`; the CV is `assets/docs/CV_AdrianCidre.pdf`. Post images stay inside each post folder.
- Styling: `assets/styles/custom_theme.scss` holds the brand palette and theme tokens (`$site-bg`, `$site-surface`, `$site-text`, `$site-heading`, `$site-link`, …) declared with `!default`, and imports `_base.scss`, `_navbar.scss` and section partials (`courses/`, `packages/`, `posts/`). Dark mode layers `_dark.scss` on top (see `_quarto.yml`) and only overrides the tokens. **Use the tokens rather than hardcoded hex colors** in components, or dark mode breaks.
- `assets/includes/buymeacoffee.qmd`: shared include added to pages with `{{< include >}}`.
- `_extensions/`: Quarto extensions (iconify, fontawesome, lightbox). Don't edit them by hand.

## Conventions

- R code in `.qmd` files declares dependencies with base R `use("pkg", "fn")` (R ≥ 4.4) or `library()`.
- Large data, `**/video/*` and `posts/data/` are gitignored, so videos in a `video/` folder never reach the deployed site (post 010 links to such videos). Keep committed media small: resize photos to about 1600 px and re-encode videos with ffmpeg, keeping the filename so frozen posts stay valid.
- Never rename `posts/NNN_slug/` folders or post media files: they are public URLs and frozen outputs reference them.
