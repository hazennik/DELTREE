#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "set"
require "uri"

root = Pathname.new(Dir.pwd)
markdown_files = Dir.glob("**/*.md", File::FNM_DOTMATCH)
  .reject { |path| path.start_with?(".git/", "build/", ".build/") }
  .sort

def local_link?(target)
  return false if target.empty?
  return false if target.start_with?("http://", "https://", "mailto:", "app://")

  true
end

def normalize_anchor(text)
  text
    .downcase
    .gsub(/<[^>]+>/, "")
    .gsub(/[`*_~]/, "")
    .gsub(/[^a-z0-9 _-]/, "")
    .strip
    .gsub(/\s+/, "-")
end

anchors_by_file = {}
markdown_files.each do |path|
  anchors = Set.new
  File.readlines(path, chomp: true).each do |line|
    next unless line =~ /\A(#{'#'}{1,6})\s+(.+?)\s*#*\z/

    anchors << normalize_anchor(Regexp.last_match(2))
  end
  anchors_by_file[Pathname.new(path).cleanpath.to_s] = anchors
end

failures = []

markdown_files.each do |path|
  source = Pathname.new(path)
  text = File.read(path)
  text.scan(/!?\[[^\]]*\]\(([^)]+)\)/).flatten.each do |raw_target|
    target = raw_target.strip
    target = target[1..-2] if target.start_with?("<") && target.end_with?(">")
    target = target.split(/\s+/, 2).first.to_s
    next unless local_link?(target)

    link_path, anchor = target.split("#", 2)
    link_path = URI::DEFAULT_PARSER.unescape(link_path.to_s)
    resolved = if link_path.empty?
                 source
               else
                 (source.dirname + link_path).cleanpath
               end

    unless (root + resolved).exist?
      failures << "#{path}: missing local link #{target}"
      next
    end

    next if anchor.to_s.empty?
    next unless resolved.extname.downcase == ".md"

    normalized_anchor = normalize_anchor(anchor)
    unless anchors_by_file.fetch(resolved.to_s, Set.new).include?(normalized_anchor)
      failures << "#{path}: missing anchor ##{anchor} in #{resolved}"
    end
  end
end

if failures.any?
  warn "Documentation link check failed:"
  failures.each { |failure| warn "  - #{failure}" }
  exit 1
end

puts "Documentation links ok."
