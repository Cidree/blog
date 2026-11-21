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
- `courses.qmd` + `courses/*.qmd`: course landing pages built from R helpers in `assets/scripts/00_courses.R` (`course_card()`, `create_course_button()`, the offer card). **Udemy coupon URLs and the coupon price are hardcoded at the top of that script.** "Update coupons" means editing them there. Course pages read reviews from `assets/data/udemy_reviews_*.csv`.
- `packages.qmd`: package cards built by `assets/scripts/packages.R`. It fetches live CRAN versions and download counts (cranlogs) at render time.
- Styling: `assets/styles/custom_theme.scss` (Sandstone theme plus SCSS variables) imports partials organized by section (`courses/`, `packages/`, `posts/`).
- `assets/includes/buymeacoffee.qmd`: shared include added to pages with `{{< include >}}`.
- `_extensions/`: Quarto extensions (iconify, fontawesome, lightbox). Don't edit them by hand.

## Conventions

- R code in `.qmd` files declares dependencies with base R `use("pkg", "fn")` (R ≥ 4.4) or `library()`.
- Large data, videos and `posts/data/` are gitignored. Small per-post data files (for example `.parquet`, `references.bib`) live inside the post folder.
