# wrap each line of the supplied text str in <p> ... </p> tags

def in_paragraphs(text)
  text.gsub(/^(.+)$/, '<p>\1</p>')
end

txt = "Frequently.\n\nReally?\n\nHow often?\n\nWell, some hundreds of times.\n"

puts in_paragraphs(txt)
# => "<p>Frequently.</p>\n\n<p>How often?</p>\n\n<p>Well, some hundreds of times.</p>\n"
