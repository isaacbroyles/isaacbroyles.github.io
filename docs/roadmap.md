# Site Roadmap

Enhancement plan for isaacbroyles.com. Each task is scoped to one PR and one working session; tasks marked **Split** list sub-tasks to do separately. This folder is excluded from the Jekyll build (`exclude:` in `_config.yml`).

## Current state

The build is in good shape: Jekyll 4.4.1 with Dart Sass (`@use` modules), Actions-based deploys, CI with html-proofer and markdownlint, grouped Dependabot, and social links in one data file. Most remaining work is front end and content.

Findings:

- **Dead theme code.** `sidebar-icon-links.html` renders GitHub and Download links from `site.github.repo` and `site.version`, neither of which is set (`jekyll-github-metadata` isn't installed). `sidebar-nav-links.html` checks `sidebar_home_link` and `sidebar_blog_link`, also unset.
- **Missing category pages.** `video-games` and `gamedev` are used by posts but have no page in `category/`, so they show as plain text and never appear in the sidebar.
- **Tags lead nowhere.** `post-tags.html` renders plain text; the tags layout was removed.
- **Related Posts is misleading.** Without `lsi`, `site.related_posts` just returns the most recent posts.
- **Dated head markup.** `maximum-scale=1` blocks pinch-zoom (WCAG 1.4.4); `X-UA-Compatible` is obsolete; the RSS `<link>` ignores `baseurl`; Google Fonts uses the old `css?family=` API without `display=swap` or preconnect; only `favicon.ico` exists (no SVG icon, apple-touch-icon, manifest, or `theme-color`).
- **No dark mode.** Colors are Sass compile-time variables, so they can't switch at runtime.
- **Accessibility gaps.** Links only underline on hover, muted text (`#767676` on white) barely passes contrast, and there's no skip link or visible `:focus-visible` style.
- **Inconsistent link targets.** CLAUDE.md says external links open in a new tab, but only about 6 links do (hand-written `{:target="_blank"}`).
- **Content hygiene.** The Unity post's filename date (2020-07-04) doesn't match its front-matter `date` (2021-07-31); `2018-07-29-cool-stuff-this.week.md` has a stray dot; `about.md` is from 2018; the 404 page has no links back; most posts lack `description` and `image`, so social previews fall back to `Profile.jpg` with a `summary` card.
- **Images.** JPGs are 330–400 KB each, with no `loading="lazy"`, width/height, or WebP/AVIF.
- **Social links.** 11 icons, including two Instagram accounts and Facebook; the Twitter icon and label are dated; no Mastodon or Bluesky.

## Phase 1: Quick wins

- [x] **T1.1 Fix the `<head>`** (`_includes/head.html`, `font-includes.html`, `favicons.html`)
  - Remove `X-UA-Compatible` and `maximum-scale=1`; use `<meta charset="utf-8">`.
  - Add `{{ site.baseurl }}` to the RSS link, or drop it since `{% feed_meta %}` from jekyll-feed already emits it.
  - Switch to the Fonts v2 URL with `&display=swap` and add `preconnect` to `fonts.gstatic.com`.
  - Add `<meta name="theme-color">`.
  - Done when: build passes and Lighthouse has no "viewport blocks zoom" warning.
- [ ] **T1.2 Remove dead theme code**
  - Delete the GitHub, Download, and version blocks in `sidebar-icon-links.html` and `sidebar.html`.
  - Delete the `sidebar_home_link`/`sidebar_blog_link` branches, or set them on purpose.
  - Remove unused SVGs (e.g. `download.svg`).
- [ ] **T1.3 Add missing category pages**
  - Add `category/video-games.md` and `category/gamedev.md`.
  - Optional: a build-time check (`_plugins` hook or CI script) that warns when a category has no page.
- [ ] **T1.4 Clean up content** (after T3.1)
  - Rename the `cool-stuff-this.week` file. The slug comes from the filename, so the URL changes; add `redirect_from` or a `permalink` to keep the old URL.
  - Reconcile the Unity post's dates: keep the original date, treat 2021 as `last_modified_at`.
  - Update `about.md`.
- [ ] **T1.5 Make the 404 page useful**
  - Links to home, recent posts, and the archive (T2.4); use `layout: page`.
- [ ] **T1.6 Add `.editorconfig`**
  - Two-space indentation, LF line endings, final newline.

## Phase 2: Information architecture and blog features

- [ ] **T2.1 Real "Related Posts"**
  - In `related_posts.html`, score posts by shared tags and categories in Liquid, falling back to recent posts. (Alternative: hide the section when nothing shares a tag.)
- [ ] **T2.2 Tag pages with `jekyll-archives`** (**Split**)
  - [ ] (a) Add the plugin and config for tags only, with an archive layout.
  - [ ] (b) Migrate categories to it and delete `category/*.md`, keeping the sidebar wiring in `category-links.html` working off `site.categories` with a curated list in `_config.yml` or `_data`.
  - [ ] (c) Link tags in `post-tags.html`.
- [ ] **T2.3 Reading time and better post meta**
  - "N min read" in `post-meta.html` via `number_of_words | divided_by: 200`.
  - Show "Updated DATE" when `last_modified_at` differs from `date`, in a `<time datetime>` element.
- [ ] **T2.4 Archive page** (`/archive/`)
  - All posts grouped by year, `sidebar_link: true`.
- [ ] **T2.5 Heading anchors**
  - Linkable h2/h3 with a hover `#`, using kramdown `auto_ids` plus a small include or `_plugins` hook. No JavaScript.
- [ ] **T2.6 Optional table of contents**
  - kramdown `{:toc}` behind front matter `toc: true`; useful for the Model Mapper and Unity posts.
- [ ] **T2.7 Post series navigation**
  - Front matter `series: <name>` plus an include listing the other parts with prev/next links (SFF PC Build, GatsbyJS).
- [ ] **T2.8 Previous/next post links** at the bottom of `post.html` (`page.previous` / `page.next`).

## Phase 3: Plugins

| Plugin | Why | Priority |
| --- | --- | --- |
| `jekyll-archives` | Tag and category pages (T2.2) | High |
| `jekyll-redirect-from` | Keep old URLs on renames and permalink changes (T1.4) | High |
| `jekyll-last-modified-at` | `last_modified_at` from git history; needs `fetch-depth: 0` in `actions/checkout` | Medium |
| `jekyll-include-cache` | Caches heavy includes like `post-meta`'s O(n²) lookup; skip unless builds get slow | Low |
| `jekyll-paginate-v2` | Only if you want paginated tag/category pages | Low |
| `jekyll_picture_tag` | Responsive images; heavy (libvips on CI), see T5.2 for a lighter route | Optional |

For each plugin: add it to the Gemfile `:jekyll_plugins` group and `_config.yml` `plugins:`, run `bundle lock --add-platform` if needed, and update CLAUDE.md.

- [ ] **T3.1 Add `jekyll-redirect-from`** (prerequisite for T1.4).
- [ ] **T3.2 Add `jekyll-last-modified-at`** and set `fetch-depth: 0` in both workflows; remove hand-written `last_modified_at` values or keep them as overrides.

## Phase 4: Look and feel

Goals: dark mode, better reading typography, accessible links, and a stronger homepage identity, done incrementally without replacing Hydeout.

- [ ] **T4.1 Colors as CSS custom properties** (no visual change)
  - Keep Sass variables for breakpoints and spacing; emit `:root { --body-bg; --body-color; --heading-color; --link-color; --border-color; --muted; --code-bg; ... }` and use them in `_base`, `_type`, `_layout`, `_posts`, `_code`, `_pagination`, `_message`.
  - Done when: screenshots before and after are identical.
- [ ] **T4.2 Dark mode**
  - `@media (prefers-color-scheme: dark)` redefining the properties, plus `color-scheme: light dark`.
  - Dark Rouge theme for `_syntax.scss` under the media query (e.g. from `rougify style github.dark`).
  - Optional T4.2b: manual toggle via `data-theme` on `<html>` and a small inline script with `localStorage`.
- [ ] **T4.3 Reading typography**
  - `max-width: 70ch` content measure, body `line-height: 1.65`, fluid type scale with `clamp()`, slightly tighter heading letter-spacing.
  - Consider a self-hosted variable WOFF2 reading face (Source Serif 4, Literata, or Inter) in `assets/fonts/`; self-host Abril Fatface too and drop Google Fonts.
- [ ] **T4.4 Accessibility**
  - Underline body links (`text-underline-offset: .2em`), add a `:focus-visible` outline.
  - Skip link in `default.html` ("Skip to content" to `#main`).
  - Raise `$gray-4` contrast to at least 4.6:1.
  - `aria-label` on sidebar `<nav>` landmarks; `prefers-reduced-motion` for button transitions.
  - Done when: Lighthouse Accessibility is 100 and axe reports no violations on home, post, and 404.
- [ ] **T4.5 Homepage hero**
  - Short intro, avatar (`isaac_broyles_bw.png`), and calls to action (Blog, Art) above the post list.
- [ ] **T4.6 Post cards on the index**
  - Title, date, reading time, tags, excerpt, optional `page.image` thumbnail; whole card clickable.
- [ ] **T4.7 Sidebar refresh**
  - Trim social icons to the 5–6 you use; move the rest to About or `/links`.
  - Update or drop Twitter; add Mastodon/Bluesky if used (`rel="me"` already supported).
  - Group nav as Home / Blog (archive) / Art / About.
- [ ] **T4.8 Code blocks**
  - Copy button (small vanilla JS in `custom-foot.html`), language label from `language-*`, `overflow-x: auto`, larger code font on mobile.
- [ ] **T4.9 Print stylesheet**
  - `@media print` hiding the sidebar and printing link URLs.

## Phase 5: Performance and media

- [ ] **T5.1 Image hygiene**
  - Recompress the IMG_*.jpg files to around 1600px wide at roughly 150 KB; add WebP/AVIF; add `loading="lazy" decoding="async"` and width/height.
- [ ] **T5.2 Lightweight responsive images** (**Split**)
  - [ ] (a) `_includes/figure.html` taking `src`, `alt`, `caption`, `width`, outputting `<figure><picture>` with WebP and JPG sources.
  - [ ] (b) `npm run images` script using `sharp` to generate variants into `assets/images/...`.
  - [ ] (c) Migrate the two posts that use images.
- [ ] **T5.3 Compressed CSS** via `sass: style: compressed` in `_config.yml`.
- [ ] **T5.4 Lighthouse CI** (**Split**; do after T4.4, and ideally T5.1)
  - Why it fits: the site is static, so `_site` can be audited with no server of our own (`staticDistDir`). Three runs on three URLs take about 1–2 minutes, and it runs as its own parallel job in `ci.yml`, so it doesn't lengthen the Jekyll build or the deploy workflow. Scores map to numeric assertions, so pass/fail is well defined.
  - Scope: PR checks only. Don't gate `pages.yml` deploys on it, because a flaky perf score shouldn't block publishing.
  - [ ] (a) Config and local run
    - `npm i -D @lhci/cli` (pin the version) and add `"lhci": "lhci autorun"` to `package.json` scripts.
    - Add `lighthouserc.json`: `collect.staticDistDir: "./_site"`, `numberOfRuns: 3` (the median is used), and `url` for `/index.html`, one post (pick a text-heavy one), and `/about/index.html`. Skip `404.html`: its HTTP 404 status trips `is-crawlable` and `http-status-code`.
    - Use mobile emulation (the Lighthouse default); it is the stricter profile.
    - Run `JEKYLL_ENV=production bundle exec jekyll build && npm run lhci` locally and record baseline scores in this file.
    - Done when: the command runs locally and prints per-URL scores.
  - [ ] (b) Assertions (pass/fail criteria)
    - Category scores, as `error`: Accessibility = 1 (set to `warn` until T4.4 lands), Best Practices ≥ 0.95, SEO ≥ 0.95, Performance ≥ 0.9. Ratchet Performance to 0.95 once T5.1 is done.
    - Metric audits, as `error`, because they are less noisy than the composite score: `largest-contentful-paint` ≤ 2500 ms, `cumulative-layout-shift` ≤ 0.1, `total-blocking-time` ≤ 200 ms.
    - Budget: `resource-summary:total:size` ≤ 500 KB per page and `resource-summary:image:size` ≤ 300 KB (needs T5.1; start at `warn`).
    - Turn off audits that only measure the CI static server, not the site: `uses-text-compression`, `uses-long-cache-ttl`, `uses-http2`. GitHub Pages already serves gzip/brotli and cache headers.
    - Leave out `is-on-https`/`redirects-http`, which don't apply on localhost.
    - Done when: a deliberate regression (e.g. removing an `<img alt>`) fails the command with a clear message, and the baseline passes.
  - [ ] (c) CI job
    - Add a `lighthouse` job to `ci.yml` (needs Ruby and Node setup, `JEKYLL_ENV=production` build, then `npm run lhci`), and cache the npm install. It runs in parallel with the other jobs.
    - Set `upload.target: temporary-public-storage` to get report links in the logs, or upload `.lighthouseci/` as an artifact instead if you'd rather not publish reports.
    - Add a step timeout (`timeout-minutes: 10`) so a hung Chrome can't stall PRs.
    - Done when: a PR shows the job in about 2 minutes or less, and a failing assertion fails the check.
  - [ ] (d) Stability and upkeep
    - Google Fonts is fetched over the network during the audit, which adds variance. Once T4.3 self-hosts fonts, tighten the thresholds.
    - If the job is flaky, raise `numberOfRuns` to 5 before loosening any threshold.
    - Document the thresholds and how to run `npm run lhci` in CLAUDE.md (Commands) and the README (T7.4).

## Phase 6: SEO and social sharing

- [ ] **T6.1 Front-matter descriptions** on every post (the excerpt is often "This is all the cool stuff I found this week.").
- [ ] **T6.2 Large preview images**
  - `twitter.card: summary_large_image`, an `image` per post, and a branded 1200×630 default OG image replacing `Profile.jpg`.
  - Optional (**Split**): auto-generated per-post OG images with `satori` or `sharp` in CI.
    - [ ] (a) Template.
    - [ ] (b) Script.
    - [ ] (c) CI step.
- [ ] **T6.3 Feed improvements**
  - Tag feeds (`feed: tags: true`), a posts limit, and a visible "Subscribe via RSS" link in the post footer.
- [ ] **T6.4 JSON-LD Person**
  - Make sure `author` has `name`, `url`, and `image`; `social.links` is already wired via `_plugins/social_links.rb`.
- [ ] **T6.5 Webmaster verification**
  - Confirm the Google and Bing meta tags are still needed; remove them if verified via DNS.

## Phase 7: Repo, tooling, and authoring

- [ ] **T7.1 Consistent external links**
  - A `_plugins/external_links.rb` `:post_render` hook adding `target="_blank" rel="noopener"` to links outside `site.url` (or `jekyll-target-blank`); remove inline `{:target}` attributes; update CLAUDE.md.
  - Decide whether you want new tabs at all; the hook makes it a one-line switch.
- [ ] **T7.2 Affiliate disclosure include**
  - `_includes/affiliate-note.html` behind front matter `affiliate: true`; `rel="sponsored"` on affiliate domains (`amzn.to`, `prf.hn`) via the T7.1 hook.
- [ ] **T7.3 Drafts and post scaffolding**
  - `_drafts/` with `jekyll serve --drafts`; a `bin/new-post "Title"` script writing standard front matter (`title`, `description`, `categories`, `tags`, `image`, `<!--more-->`).
- [ ] **T7.4 README.md** covering setup, `serve`, writing a post, and deploys.
- [ ] **T7.5 Weekly external link check**
  - Scheduled workflow running html-proofer with external links, opening an issue on failure.
- [ ] **T7.6 Pin Actions to SHAs** (Dependabot keeps them current).
- [ ] **T7.7 Privacy-friendly analytics**
  - Consider Plausible, GoatCounter, or Cloudflare Web Analytics instead of GA4; if keeping GA4, add a `/privacy` page.

## Phase 8: Beyond the blog

- [ ] **T8.1 Projects page** (`/projects/`) (**Split**)
  - [ ] (a) `_data/projects.yml` (or a `_projects` collection) and card layout.
  - [ ] (b) Content.
- [ ] **T8.2 Art gallery** (`/art/`) (**Split**)
  - [ ] (a) `_art` collection or `_data/art.yml` and layout.
  - [ ] (b) CSS grid and native `<dialog>` lightbox, reusing T5.2.
  - [ ] (c) Content.
- [ ] **T8.3 `/now` page.**
- [ ] **T8.4 `/uses` page**, linking the PC build posts.
- [ ] **T8.5 Notes/TIL collection** (`_notes`) for short-form posts like "Cool Stuff This Week", so long-form articles stand out.
- [ ] **T8.6 Comments (optional)** via giscus in `post.html` behind `comments: true`.

## Suggested order

1. Phase 1 (T1.1–T1.6), with T3.1 before T1.4.
2. T4.1 → T4.2 → T4.4: color tokens, dark mode, accessibility.
3. T4.3, T4.5, T4.7: typography, hero, sidebar.
4. Phase 2, including T2.2's plugin work.
5. Phase 5 and T5.4 to lock in the gains.
6. Phase 6.
7. Phase 7, in any order.
8. Phase 8, at your own pace.
