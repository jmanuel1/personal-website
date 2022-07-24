# TODO: ADD TESTS

require 'digest'
require 'kramdown'
require 'logger'
require 'word_wrap'
require 'word_wrap/core_ext'

IN_DOCUMENT = 0
IN_PROGRAM = 1
IN_FRONTMATTER = 2
IN_PARAGRAPH = 3

# The extension is chosen to be one unlikely to appear in an actual file path
# ever.
INTERNAL_LITERATE_EXTENSION_NAME = '///.md.literate///'

def create_logger(name)
  logger = Logger.new(STDERR)
  logger.level = Logger::INFO
  logger.progname = name
  logger.formatter = -> (severity, datetime, progname, message) {
    "#{color_by_severity(severity)} #{progname}: #{message}\n"
  }
  logger
end

def color_by_severity(severity)
  if severity == 'UNKNOWN' then
    severity
  elsif severity == 'FATAL' then
    severity.red.bold
  elsif severity == 'ERROR' then
    severity.red
  elsif severity == 'WARN' then
    severity.yellow
  else
    severity.cyan
  end
end

module Jekyll
  class LiteratePostGenerator < Generator
    @@logger = create_logger('LiteratePostGenerator')

    @@temporary_files = []

    @@site_url = nil

    def self.site_url
      @@logger.debug "reading @@site_url: #{@@site_url}"
      @@site_url
    end

    safe true
    priority :lowest

    def generate(site)
      if site.config.fetch('debug', false) then
        @@logger.level = Logger::DEBUG
      end

      @@site_url = site.config['url']

      site.posts.docs.each do |post|
        if post.data.fetch('literate', false) then
          dir = File.dirname(post.path)
          name = File.basename(post.path)
          page = LiteratePage.new(site, site.source, dir, name)
          page.destination_dir = File.dirname(post.destination(site.dest))
          page.post_url_relative_to_site_url = post.url
          page.logger_level = @@logger.level
          site.pages << page
        end
      end
    end


    def self.<=>(*)
      1
    end
  end

  class LiteratePage < Page
    attr_accessor :destination_dir, :post_url_relative_to_site_url
    attr_reader :logger_level

    @@logger = create_logger('LiteratePage')

    def initialize(*args)
      super(*args)
      @destination_dir = nil
      @post_url_relative_to_site_url = nil
      @@logger.level = @logger_level = Logger::INFO
    end

    def destination(dest)
      if @destination_dir != nil then
        return File.join(@destination_dir, "code.py")
      end
      return super(dest)
    end

    # Override path so that Jekyll can use the absolute path to the temp file,
    # instead of trying to compute the source path from relative_path.
    # relative_path is actually the absolute path to the temp file.
    def path
      relative_path
    end

    # Override extname so that the Jekyll converter can match against it without
    # its work being clobbered by the Markdown converter.
    def extname
      INTERNAL_LITERATE_EXTENSION_NAME
    end

    def place_in_layout?
      false
    end

    def logger_level=(level)
      @@logger.level = @logger_level = level
    end
  end

  class LiterateConverter < Converter
    safe true
    priority :high

    def initialize(config)
      super(config)

      # Since the convert method is not given metadata, we grab it in a hook.
      Jekyll::Hooks.register :pages, :pre_render do |post|
        if matches(post.extname)
          @config[:post_url_relative_to_site_url] = post.post_url_relative_to_site_url
        end
      end

      Jekyll::Hooks.register :pages, :post_render do |post|
        if matches(post.extname)
          @config.delete(:post_url_relative_to_site_url)
        end
      end
    end

    def matches(extension)
      extension.end_with? INTERNAL_LITERATE_EXTENSION_NAME
    end

    def output_ext(extension)
      '.py'
    end

    def convert(content)
      options = {
        'html_to_native' => true,
        :input => 'GFM',
        :post_url_relative_to_site_url => @config[:post_url_relative_to_site_url],
        :site_url => @config[:site_url],
        :logger_level => @config[:logger_level]
      }
      # assume the default markdown renderer (kramdown)
      ::Kramdown::Document.new(content, options).to_literate
    end
  end
end

UNORDERED_LIST = 0
ORDERED_LIST = 1

module Kramdown::Converter
  class Literate < Base
    @@logger = create_logger('Literate')

    def initialize(*args)
      super(*args)
      @site_url = ::Jekyll::LiteratePostGenerator.site_url
      @post_url_relative_to_site_url = @options[:post_url_relative_to_site_url]

      @hide_next_program_fragment = false
      @output_next_program_fragment_as_prose = false
      @indentation_level = 0
      @list_type = nil
      @is_in_paragraph = false
      @item_number = 0
    end

    def word_wrap_length
      79 - @indentation_level
    end

    def convert(element)
      element.children = element.children.select { |child|
        child.type != :blank and child.type != :br #and (child.type != :text or child.value.strip != '')
      }
      send("convert_#{element.type}", element)
    end

    def convert_smart_quote(element)
      "'"
    end

    def convert_root(element)
      element.children.map { |child| convert(child) }
        .select { |piece| piece != nil }
        .join("\n")
    end

    def convert_xml_comment(element)
      if element.options[:category] != :block then
        element.value
      else
        text = nil
        case element.value
        when /^<!--\s*hide\s*-->/
          @hide_next_program_fragment = true
        when /^<!--\s*output_as_prose\s*-->/
          @output_next_program_fragment_as_prose = true
        when /^<!--\s*backlink\s*-->/
          wrap_width = 79 - '# '.length
          post_link = File.join(@site_url, @post_url_relative_to_site_url)
          backlink_text = "This is the code for the tutorial at #{post_link}.".fit wrap_width
          # Always have newlines after backlinks.
          text = backlink_text.split("\n").map { |line| "\# #{line}" }.join("\n") + "\n"
        when /^<!--\s*add_to_indentation_level\s+(-?\d+)\s*-->/
          @indentation_level += $1.to_i
        end
        text
      end
    end

    def convert_p(element)
      text = nil
      unless @hide_next_program_fragment
        text = with_suppressed_hash_and_indent {
          element.children.map { |child| convert(child) }.join("")
        }
        if element.options[:transparent] then
          return text
        end
        wrap_width = word_wrap_length - '# '.length
        text = text.fit wrap_width
        lines = text.split "\n"
        # Always have newlines after visible opaque paragraphs.
        text = lines.map { |line| "#{' ' * @indentation_level}\# #{line}" }.join("\n") + "\n"
      end
      @hide_next_program_fragment = false
      text
    end

    def convert_text(element)
      element.value
    end

    def convert_a(element)
      link_text = element.children.map { |child| convert(child) }.join("").strip
      "[#{link_text}](#{element.attr['href']})"
    end

    def convert_em(element)
      element.children.map { |child| convert(child) }.join("")
    end

    def convert_codespan(element)
      element.value
    end

    def convert_html_element(element)
      send("convert_#{element.value}_html_element", element)
    end

    def convert_details_html_element(element)
      element.children.select { |child| child.type != :text or child.value.strip != '' }.map { |child|
        child_text = convert(child).strip
        lines = child_text.split "\n"
        if child.type == :text then
          wrap_width = word_wrap_length - '# '.length
          lines = child_text.fit(wrap_width).split("\n").map { |line| " " * @indentation_level + '# ' + line }
        end
        # Always add a newline after each child in a details element.
        lines.join("\n") + "\n"
      }.join("\n")
    end

    # container, no word wrap
    def convert_summary_html_element(element)
      hash_and_indent = " " * @indentation_level + '# '
      element.children.map { |child| hash_and_indent + convert(child) }.join('').strip
    end

    def convert_ul(element)
      with_list_type(UNORDERED_LIST) {
        element.children.map { |child|
          convert(child).rstrip
        }.join("\n")
      } + "\n" # Always have a newline after an unordered list.
    end

    def convert_li(element)
      hash = ''
      if not @is_in_paragraph then
        hash = "#{' ' * @indentation_level}\# "
      end
      element.children.each_with_index.map { |child, index|
        case @list_type
        when UNORDERED_LIST
          bullet = '* '
        when ORDERED_LIST
          @item_number += 1
          bullet = "#{@item_number}. "
        end

        original_indentation_level = @indentation_level
        if child.type == :ul or child.type == :ol then
          @indentation_level += "\# ".length + bullet.length
        end
        element_text = convert(child)
        @indentation_level = original_indentation_level

        if child.type == :ul or child.type == :ol then
          text = "\n" + element_text
        else
          wrap_width = word_wrap_length - "\# ".length - bullet.length
          text = element_text.fit(wrap_width).split("\n").join("\n#{hash}" + " " * bullet.length)
        end
        if index == 0 then
          hash + bullet + text
        else
          text
        end
      }.join('')
    end

    # inline, no word wrap
    def convert_img(element)
      alt_text = element.attr['alt']
      url = File.join(@site_url, element.attr['src'])
      "(See image at #{url}. Image description: #{alt_text})"
    end

    # inline, no word wrap
    def convert_strong(element)
      text = element.children.map { |child| convert(child) }.join('').strip
      "**#{text}**"
    end

    def convert_codeblock(element)
      text = nil
      text = element.value.rstrip unless @hide_next_program_fragment
      if text == nil then
        return nil
      end

      if @output_next_program_fragment_as_prose then
        text = text.split("\n").map { |line| "\# #{line}" }.join("\n")
      elsif not @hide_next_program_fragment and not @output_next_program_fragment_as_prose
        last_line = element.value.split("\n")[-1]
        @indentation_level = last_line.length - last_line.lstrip.length
      end
      @output_next_program_fragment_as_prose = @hide_next_program_fragment = false
      # Always have a newline after a code block.
      text + "\n"
    end

    def convert_header(element)
      marker = "\#" * (element.options[:level] + 1)
      wrap_width = word_wrap_length - marker.length
      header_text = element.options[:raw_text].fit wrap_width
      header_lines = header_text.split "\n"
      # Always have a newline after a header.
      header_lines.map { |line| "#{' ' * @indentation_level}#{marker} #{line}" }.join("\n") + "\n"
    end

    def with_suppressed_hash_and_indent(&block)
      original_is_in_paragraph = @is_in_paragraph
      @is_in_paragraph = true
      result = block.()
      @is_in_paragraph = original_is_in_paragraph
      result
    end

    def with_list_type(list_type, &block)
      original_list_type = @list_type
      @list_type = list_type
      result = block.()
      @list_type = original_list_type
      result
    end

    def method_missing(symbol, *args)
      if not symbol.to_s.start_with? 'convert_' then
        return super(symbol, *args)
      end

      @@logger.debug "Using default conversion for #{symbol}"
      if symbol == :convert_blank or symbol == :convert_br then
        @@logger.warn "Converting a blank or br element, which is probably not what I intend"
      end

      element = args[0]

      if root.children then
        root.children.map { |child| convert(child) }.join("\n")
      else
        root.value
      end
    end
  end
end
