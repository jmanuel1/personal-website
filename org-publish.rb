require 'org-ruby'

def main
  path = File.join(".org", "#{ARGV[0]}.org")

  content = File.read(path)
  title = extract_title(content)
  # https://github.com/wallyqs/org-ruby/issues/30
  options = { :skip_rubypants_pass => true }
  # Front matter doesn't appear in markdown, so use html
  markup = Orgmode::Parser.new(content, options).to_html

  # TODO: Warn if there seems to be a published version
  # TODO: Regenerate published posts (will need to change last_modified_at)
  # Use .md extension anyway to support https://github.com/robcrocombe/jekyll-post
  target = File.join("_drafts", "#{ARGV[0]}.md")
  puts "Writing to #{target}\n"
  FileUtils.mkdir "_drafts" unless File.exist? "_drafts"
  File.write(target, markup)

  puts "#{path} exported to _drafts as HTML\n"
end

main
