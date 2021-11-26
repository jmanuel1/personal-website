require 'digest'
require 'kramdown'
require 'logger'
require 'tempfile'
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

    safe true
    priority :lowest

    def generate(site)
      if site.config.fetch('debug', false) then
        @@logger.level = Logger::DEBUG
      end

      site.posts.docs.each do |post|
        if post.data.fetch('literate', false) then
          result = generate_code(post, site)
          static_file = LiterateStaticFile.new(site, site.source, result[:dir], result[:name])
          static_file.destination_dir = File.dirname(post.destination(site.dest))
          site.static_files << static_file
        end
      end
    end

    def generate_code(post, site)
      post_path = post.path
      post_content = File.read(post_path)
      program_content = post_to_program(post_content, post.url, site.config['url'])
      hash = Digest::SHA256.hexdigest post_content
      f = Tempfile.new(['literate-output', '.py'])
      # Prevent f from being garbaged collected so it isn't unlinked before
      # Jekyll copies from it.
      @@temporary_files << f
      output_path = f.path
      @@logger.debug "Writing generated code to #{output_path}"
      f.write(program_content)
      { dir: File.dirname(output_path), name: File.basename(output_path) }
    end

    def post_to_program(document, post_url_relative_to_site_url, site_url)
      document = strip_frontmatter(document)
      options = {
        'html_to_native' => true,
        :input => 'GFM',
        :post_url_relative_to_site_url => post_url_relative_to_site_url,
        :site_url => site_url,
        :logger_level => @@logger.level
      }
      # assume the default markdown renderer (kramdown)
      ::Kramdown::Document.new(document, options).to_literate
    end

    def strip_frontmatter(document)
      was_in_frontmatter = false
      document_lines = document.split("\n")
      stripped_lines = []
      state = IN_DOCUMENT
      document_lines.each_with_index { |line, i|
        case state
        when IN_DOCUMENT
          case line
          when /^---$/
            unless was_in_frontmatter
              state = IN_FRONTMATTER
              was_in_frontmatter = true
            end
          else
            stripped_lines << line
          end
        when IN_FRONTMATTER
          case line
          when /^---$/
            state = IN_DOCUMENT
          end
        end
      }
      stripped_lines.join("\n")
    end

    def self.<=>(*)
      1
    end
  end

  class LiterateStaticFile < StaticFile
    attr_accessor :destination_dir
    def initialize(*args)
      super(*args)
      @destination_dir = nil
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
  end
end

module Kramdown::Converter
  class Literate < Base
    @@logger = create_logger('Literate')

    def initialize(*args)
      super(*args)
      @@logger.level = @options[:logger_level]
      @site_url = @options[:site_url]
      @post_url_relative_to_site_url = @options[:post_url_relative_to_site_url]

      @hide_next_program_fragment = false
      @output_next_program_fragment_as_prose = false
      @indentation_level = 0
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
        text = element.children.map { |child| convert(child) }.join("")
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
        child_text = convert(child).strip
        # FIXME: Wrap words here. It currently breaks how lists display.
        lines = child_text.split "\n"
        lines.map { |line| "#{' ' * @indentation_level}\# #{line}" }.join("\n") + "\n"
      }.join("\n").strip
    end

    def convert_summary_html_element(element)
      element.children.map { |child| convert(child) }.join('').strip
    end

    def convert_ul(element)
      element.children.map { |child|
        child_text = convert(child).strip
        "* #{child_text}"
      }.join("\n").strip
    end

    def convert_li(element)
      element.children.map { |child| convert(child) }.join('').strip
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
