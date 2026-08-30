#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/validate-changelog.sh <vX.Y.Z[-prerelease]> [--notes-output PATH] [--html-output PATH] [--env-output PATH]

Validates that CHANGELOG.md has a dated release section matching the tag and
extracts release notes for GitHub Releases and Sparkle appcasts.
EOF
}

if (($# == 0)); then
  usage >&2
  exit 2
fi

tag="$1"
shift
notes_output=""
html_output=""
env_output=""

while (($#)); do
  case "$1" in
    --notes-output)
      shift
      notes_output="${1:-}"
      ;;
    --html-output)
      shift
      html_output="${1:-}"
      ;;
    --env-output)
      shift
      env_output="${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

repo_root="${0:A:h:h}"
changelog="${DELTREE_CHANGELOG_PATH:-$repo_root/CHANGELOG.md}"

ruby - "$changelog" "$tag" "$notes_output" "$html_output" "$env_output" <<'RUBY'
require "cgi"
require "date"
require "fileutils"

changelog, tag, notes_output, html_output, env_output = ARGV

unless tag.match?(/\Av\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?\z/)
  warn "Release tag must be SemVer-like and start with v: #{tag}"
  exit 2
end

version = tag.delete_prefix("v")
marketing_version = version.split("-", 2).first

content = File.read(changelog)
section_match = content.match(/^## \[#{Regexp.escape(version)}\] - (?<date>\d{4}-\d{2}-\d{2})\n(?<body>.*?)(?=^## |\z)/m)
unless section_match
  warn "CHANGELOG.md must contain a dated release section: ## [#{version}] - YYYY-MM-DD"
  exit 1
end

begin
  Date.iso8601(section_match[:date])
rescue ArgumentError
  warn "CHANGELOG.md release date is not ISO-8601: #{section_match[:date]}"
  exit 1
end

notes = section_match[:body].lines.map(&:rstrip)
notes.shift while notes.first&.empty?
notes.pop while notes.last&.empty?

if notes.empty? || notes.none? { |line| line.start_with?("- ") }
  warn "CHANGELOG.md release section #{version} must contain user-facing bullet notes."
  exit 1
end

def markdown_to_html(lines)
  html = []
  in_list = false
  lines.each do |line|
    case line
    when /\A### (.+)\z/
      if in_list
        html << "</ul>"
        in_list = false
      end
      html << "<h3>#{CGI.escapeHTML($1)}</h3>"
    when /\A#### (.+)\z/
      if in_list
        html << "</ul>"
        in_list = false
      end
      html << "<h4>#{CGI.escapeHTML($1)}</h4>"
    when /\A- (.+)\z/
      unless in_list
        html << "<ul>"
        in_list = true
      end
      html << "<li>#{CGI.escapeHTML($1)}</li>"
    when /\A\s*\z/
      next
    else
      if in_list
        html << "</ul>"
        in_list = false
      end
      html << "<p>#{CGI.escapeHTML(line)}</p>"
    end
  end
  html << "</ul>" if in_list
  html.join("\n")
end

unless notes_output.empty?
  FileUtils.mkdir_p(File.dirname(notes_output))
  File.write(notes_output, notes.join("\n") + "\n")
end

unless html_output.empty?
  FileUtils.mkdir_p(File.dirname(html_output))
  File.write(html_output, markdown_to_html(notes) + "\n")
end

unless env_output.empty?
  File.open(env_output, "a") do |file|
    file.puts "DELTREE_RELEASE_VERSION=#{version}"
    file.puts "DELTREE_MARKETING_VERSION=#{marketing_version}"
  end
end

puts "Validated CHANGELOG.md release notes for #{version}."
RUBY
