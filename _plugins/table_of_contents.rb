# frozen_string_literal: true

# Opt-in table of contents: a post with `toc: true` in its front matter gets a
# kramdown-generated list of its h2/h3 headings (see `kramdown.toc_levels` in
# _config.yml). It is inserted right after the `<!--more-->` excerpt separator
# so the index excerpt stays clean, or at the top when there is no separator.
# Styled in _sass/hydeout/_posts.scss.
TOC_MARKUP = <<~MARKDOWN
  <nav class="toc" aria-label="Table of contents" markdown="1">

  **Contents**

  * TOC
  {:toc}

  </nav>

MARKDOWN

Jekyll::Hooks.register :documents, :pre_render do |doc|
  next unless doc.collection.label == "posts" && doc.data["toc"]

  separator = doc.data["excerpt_separator"] || "<!--more-->"
  index = doc.content.index(separator)
  doc.content =
    if index
      split = index + separator.length
      "#{doc.content[0...split]}\n\n#{TOC_MARKUP}#{doc.content[split..]}"
    else
      "#{TOC_MARKUP}#{doc.content}"
    end
end
