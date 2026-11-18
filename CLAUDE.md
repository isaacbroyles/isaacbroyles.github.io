# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal blog/site (<https://www.isaacbroyles.com>) built with Jekyll and hosted on GitHub Pages. The theme is a vendored copy of **Hydeout** (layouts in `_layouts/`, partials in `_includes/`, styles in `_sass/hydeout/`), so theme changes are made directly in this repo rather than via a gem. Pushing to `master` runs `.github/workflows/pages.yml`, which builds with `bundle exec jekyll build` (Ruby from `.ruby-version`, gems from `Gemfile.lock`) and deploys via GitHub Actions (Pages source must be set to "GitHub Actions").

## Commands

```sh
bundle install                 # install Jekyll + plugins (versions pinned by the committed Gemfile.lock)
bundle exec jekyll serve       # local dev server at http://localhost:4000, output in _site/
bundle exec jekyll build       # one-off build
JEKYLL_ENV=production bundle exec jekyll build   # build with analytics enabled
```

There are no tests. `.github/workflows/ci.yml` runs on pull requests: it builds the site, runs html-proofer on `_site` (internal links and images only; `bundle exec htmlproofer ./_site --disable-external --no-enforce-https` locally), and lints Markdown with `npm run lint:md` (markdownlint-cli2, pinned in `package.json`, rules from `.markdownlint.json` with MD002 and MD013/line-length disabled). html-proofer is in the Gemfile's `:test` group. Run `npm install` once to get the linter; a Claude Code `PostToolUse` hook (`.claude/hooks/markdownlint.sh`, wired in `.claude/settings.json`) lints each Markdown file after Claude edits it and reports errors back.

The Gemfile uses Jekyll 4.3 with explicitly listed plugins (not the `github-pages` gem). Plugins are declared in the Gemfile's `:jekyll_plugins` group and enabled under `plugins:` in `_config.yml`; keep the two in sync.

## Claude Code plugin

The project uses the `git-workflow` plugin (the `git-workflow:github-flow` skill) from the `ai-sdlc` marketplace, declared in `.claude/settings.json` via `extraKnownMarketplaces` and `enabledPlugins`. Claude Code prompts to install it when the folder is trusted; to install manually, run `/plugin marketplace add isaacbroyles/ai-sdlc` then `/plugin install git-workflow@ai-sdlc`.

## Roadmap tasks

`docs/roadmap.md` lists enhancement tasks by ID (e.g. T1.4, T2.2b), each scoped to one PR. When asked to do a roadmap task, always use the `git-workflow:github-flow` skill end to end: branch from the latest `master`, implement, commit, push, open a PR, wait for CI, merge, and clean up.

- Name the branch after the task's title in kebab-case (e.g. `clean-up-content`, `add-missing-category-pages`).
- Put the task ID in the commit subject and PR title, e.g. `Add missing category pages for video-games and gamedev (T1.3)`.
- In the same PR, check off the task (`- [ ]` → `- [x]`) in `docs/roadmap.md`; for **Split** tasks, check off only the sub-task done, and the parent once all sub-tasks are done.
- Respect stated prerequisites (e.g. "after T3.1"); if one isn't done, say so before starting.
- Before opening the PR, run the CI checks locally where possible (`bundle exec jekyll build`, html-proofer, `npm run lint:md`) and confirm the task's "Done when" criteria.
- Once CI passes, merge with a merge commit (`gh pr merge --merge --delete-branch`) without asking for confirmation. Still stop if a review is required or checks fail.

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
