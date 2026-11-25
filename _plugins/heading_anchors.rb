# frozen_string_literal: true

# Add a "#" permalink to every h2/h3 that kramdown gave an id. This runs on the
# converted post body, before the layout wraps it, so sidebar and "Related
# Posts" headings are left alone. The link is revealed on hover in
# _sass/hydeout/_posts.scss.
HEADING_WITH_ID = %r{<(h[23]) id="([^"]+)"([^>]*)>(.*?)</\1>}m.freeze

Jekyll::Hooks.register :documents, :post_convert do |doc|
  next unless doc.collection.label == "posts"

  doc.content = doc.content.gsub(HEADING_WITH_ID) do
    tag = Regexp.last_match(1)
    id = Regexp.last_match(2)
    attrs = Regexp.last_match(3)
    inner = Regexp.last_match(4)
    %(<#{tag} id="#{id}"#{attrs}>#{inner} <a class="heading-anchor" href="##{id}" aria-label="Link to this section">#</a></#{tag}>)
  end
end
