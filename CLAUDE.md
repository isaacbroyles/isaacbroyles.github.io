# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal blog/site (www.isaacbroyles.com) built with Jekyll and hosted on GitHub Pages. The theme is a vendored copy of **Hydeout** (layouts in `_layouts/`, partials in `_includes/`, styles in `_sass/hydeout/`), so theme changes are made directly in this repo rather than via a gem. Pushing to `master` runs `.github/workflows/pages.yml`, which builds with `bundle exec jekyll build` (Ruby from `.ruby-version`, gems from `Gemfile.lock`) and deploys via GitHub Actions (Pages source must be set to "GitHub Actions").

## Commands

```sh
bundle install                 # install Jekyll + plugins (versions pinned by the committed Gemfile.lock)
bundle exec jekyll serve       # local dev server at http://localhost:4000, output in _site/
bundle exec jekyll build       # one-off build
JEKYLL_ENV=production bundle exec jekyll build   # build with analytics enabled
```

There are no tests. Markdown is linted with markdownlint using `.markdownlint.json` (MD002 and MD013/line-length disabled).

The Gemfile uses Jekyll 4.3 with explicitly listed plugins (not the `github-pages` gem). Plugins are declared in the Gemfile's `:jekyll_plugins` group and enabled under `plugins:` in `_config.yml`; keep the two in sync.

## Content conventions

- Posts live in `_posts/YYYY-MM-DD-slug.md`. `layout: post`, `excerpt_separator: <!--more-->`, and the author come from `defaults`/`author` in `_config.yml`. Front matter typically includes `title`, `date`, `last_modified_at`, `categories`, `tags`, and often an explicit `permalink` (e.g. `/art-links`). Place `<!--more-->` after the intro to control the excerpt on the paginated index (`paginate: 5`).
- Posts containing literal Liquid syntax (e.g. GitHub Actions `${{ }}` expressions) must wrap it in `{% raw %}...{% endraw %}`; a missing `endraw` breaks the build.
- Categories: each category needs a page in `category/` with `layout: category` and a `category:` value matching the post's `categories` entry. These pages are auto-added to the sidebar via `_includes/category-links.html`.
- Standalone pages (e.g. `about.md`) appear in the sidebar when their front matter has `sidebar_link: true` (`_includes/page-links.html`).
- External links in posts are written to open in a new tab (`target="_blank"`). Some posts contain affiliate links with a disclosure note.
- Images go in `assets/images/`; the default social/SEO image is set via `defaults` in `_config.yml`.

## Site wiring

- `_config.yml` holds site metadata, social links, SEO/Twitter config, and the Google Analytics 4 ID. GA (gtag, `google_analytics_ga`) is only emitted when `jekyll.environment == 'production'` (see `_includes/google-analytics.html`), which the Pages workflow sets via `JEKYLL_ENV: production`.
- Site customization hooks: `_includes/custom-head.html`, `custom-foot.html`, `custom-nav-links.html`, `custom-icon-links.html`.
- `.well-known/` is explicitly included in the build via `include:` in `_config.yml` (Keybase verification); `CNAME` sets the custom domain.
