# frozen_string_literal: true

module DocsLinkHelpers
  module_function

  def strip_html_tags(text)
    current = text.dup
    loop do
      stripped = current.gsub(/<[^>]+>/, "")
      return stripped if stripped == current

      current = stripped
    end
  end

  def normalize_anchor(text)
    strip_html_tags(text)
      .downcase
      .gsub(/[`*_~]/, "")
      .gsub(/[^a-z0-9 _-]/, "")
      .strip
      .gsub(/\s+/, "-")
  end
end
