#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "docs_link_helpers"

cases = {
  "Install <code>DELTREE</code>" => "install-deltree",
  "Nested <em><strong>Title</strong></em>" => "nested-title",
  "Safety <scrip<script>ignored</script>t>alert" => "safety-ignoredtalert",
}

cases.each do |input, expected|
  actual = DocsLinkHelpers.normalize_anchor(input)
  abort "Expected #{input.inspect} to normalize to #{expected.inspect}, got #{actual.inspect}." unless actual == expected
end

puts "Documentation anchor tests passed."
