require 'digest'
require 'kramdown'
require 'logger'
require 'word_wrap'
require 'word_wrap/core_ext'

IN_DOCUMENT = 0
IN_PROGRAM = 1
IN_FRONTMATTER = 2
IN_PARAGRAPH = 3

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

    def extname
      '.md.literate'
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
      extension =~ /^\.md\.literate$/i
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
    end

    def convert(element)
      send("convert_#{element.type}", element)
    end

    def convert_smart_quote(element)
      "'"
    end

    def convert_root(element)
      element.children.map { |child| convert(child) }.join("\n")
    end

    def convert_blank(element)
      "\n"
    end

    def convert_xml_comment(element)
      if element.options[:category] != :block then
        element.value
      else
        case element.value
        when /^<!--\s*hide\s*-->/
          @hide_next_program_fragment = true
          ""
        when /^<!--\s*output_as_prose\s*-->/
          @output_next_program_fragment_as_prose = true
          ""
        when /^<!--\s*backlink\s*-->/
          wrap_width = 79 - '# '.length
          post_link = File.join(@site_url, @post_url_relative_to_site_url)
          backlink_text = "This is the code for the tutorial at #{post_link}.".fit wrap_width
          backlink_text.split("\n").map { |line| "\# #{line}" }.join("\n") + "\n"
        when /^<!--\s*add_to_indentation_level\s+(-?\d+)\s*-->/
          @indentation_level += $1.to_i
          ""
        end
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
        wrap_width = 79 - '# '.length - @indentation_level
        text = text.fit wrap_width
        lines = text.split "\n"
        text = lines.map { |line| "#{' ' * @indentation_level}\# #{line}" }.join("\n") + "\n"
      end
      @hide_next_program_fragment = false
      text
    end

    def convert_text(element)
      element.value
    end

    def convert_br(element)
      ""
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
      element.children.map { |child|
        child_text = with_suppressed_hash_and_indent {
          convert(child).strip
        }
        # FIXME: Wrap words here. It currently breaks how lists display.
        lines = child_text.split "\n"
        lines.map { |line| "#{' ' * @indentation_level}\# #{line}" }.join("\n") + "\n"
      }.join("\n").strip
    end

    def convert_summary_html_element(element)
      element.children.map { |child| convert(child) }.join('').strip
    end

    def convert_ul(element)
      with_list_type(UNORDERED_LIST) {
        element.children.map { |child|
          text = with_suppressed_hash_and_indent {
            convert(child).strip
          }
          hash = ''
          if not @is_in_paragraph then
            hash = "#{' ' * @indentation_level}\# "
          end
          lines = text.split("\n")
          len = lines.length
          if len >= 1 then
            lines[0] = "#{hash}#{lines[0]}"
          end
          lines[(1..len)] = lines[(1..len)].map { |line| "#{hash}  #{line}" }
          lines.join("\n")
        }.join("\n").strip
      }
    end

    def convert_li(element)
      item_number = 1
      item_text = element.children.map { |child| convert(child) }.join('').strip
      case @list_type
      when UNORDERED_LIST
        '* ' + item_text
      when ORDERED_LIST
        text = "#{item_number}. #{item_text}"
        item_number += 1
        text
      end
    end

    def convert_img(element)
      alt_text = element.attr['alt']
      url = File.join(@site_url, element.attr['src'])
      "(See image at #{url}. Image description: #{alt_text})"
    end

    def convert_strong(element)
      text = element.children.map { |child| convert(child) }.join('').strip
      "**#{text}**"
    end

    def convert_codeblock(element)
      text = ''
      text = element.value unless @hide_next_program_fragment
      if @output_next_program_fragment_as_prose then
        text = text.split("\n").map { |line| "\# #{line}" }.join("\n") + "\n"
      elsif not @hide_next_program_fragment and not @output_next_program_fragment_as_prose
        last_line = element.value.split("\n")[-1]
        @indentation_level = last_line.length - last_line.lstrip.length
      end
      @output_next_program_fragment_as_prose = @hide_next_program_fragment = false
      text
    end

    def convert_header(element)
      marker = "\#" * (element.options[:level] + 1)
      wrap_width = 78 - marker.length - @indentation_level
      header_text = element.options[:raw_text].fit wrap_width
      header_lines = header_text.split "\n"
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

      element = args[0]

      if root.children then
        root.children.map { |child| convert(child) }.join("\n")
      else
        root.value
      end
    end
  end
end
