# frozen_string_literal: true

# jekyll-seo-tag reads profile links from site.social.links in _config.yml.
# Fill that in from _data/social.yml so the sidebar icons and the SEO
# metadata share one list.
Jekyll::Hooks.register :site, :post_read do |site|
  links = site.data.fetch("social", []).map { |link| link["url"] }
  site.config["social"] = (site.config["social"] || {}).merge("links" => links)
end
