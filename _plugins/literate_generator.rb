require 'digest'
require 'kramdown'

IN_DOCUMENT = 0
IN_PROGRAM = 1
IN_FRONTMATTER = 2
IN_PARAGRAPH = 3

module Jekyll
  class LiteratePostGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      @site_url = site.config['url']
      site.posts.each do |post|
        print "post #{post.path} data: "
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
      program_content = post_to_program(post_content, File.join(site.config['url'], post.url))
      hash = Digest::SHA256.hexdigest post_content
      output_dir = File.join(site.source, ".literate-output")
      output_path = File.join(site.source, ".literate-output/#{hash}.py")
      print "Writing generated code to #{output_path}\n"
      Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
      File.write(output_path, program_content, { mode: 'w' })
      result = { dir: ".literate-output", name: "#{hash}.py" }
    end

    def post_to_program(document, post_link)
      program_lines = []

      state = IN_DOCUMENT
      hide_next_program_fragment = false
      output_next_program_fragment_as_prose = false
      current_program_line = 0

      line_map = {}

      document = parse_markdown(strip_frontmatter(document))
      inline_actions = {
        smart_quote: -> (el) { "'" },
        a: -> (el) {
          p el.attr
          p el.children
          p el.value
          el.children.map { |child| inline_traverse(child, inline_actions) }.join("")
        },
        em: -> (el) {
          el.children.map { |child| inline_traverse(child, inline_actions) }.join("")
        }
      }
      actions = {}
      actions[:codeblock] = -> (el) {
        text = nil
        text = el.value unless hide_next_program_fragment
        hide_next_program_fragment = false
        text
      }
      actions[:xml_comment] = -> (el) {
        if el.options[:category] != :block then
          el.value
        else
          case el.value
          when /^<!--\s*hide\s*-->/
            hide_next_program_fragment = true
            nil
          when /^<!--\s*output_as_prose\s*-->/
            output_next_program_fragment_as_prose = true
            nil
          when /^<!--\s*backlink\s*-->/
            "\# This is the code for the tutorial at #{post_link}."
          end
        end
      }
      actions[:p] = -> (el) {
        text = el.children.map { |child| inline_traverse(child, inline_actions) }.join("")
        lines = text.split "\n"
        if hide_next_program_fragment then
          text = nil
        else
          text = lines.map { |line| "\# #{line}" }.join("\n")
        end
        hide_next_program_fragment = false
        text
      }
      actions[:header] = -> (el) {
        marker = "\#" * el.options[:level]
        "#{marker} #{el.options[:raw_text]}"
      }

      program_lines = traverse(document.root, actions)


      # document_lines.each_with_index { |line, i|
      #   case state
      #   when IN_DOCUMENT
      #     case line
      #     when /^```python/
      #       state = IN_PROGRAM
      #     when /^    .*/
      #       program_lines << line[4..]
      #       state = IN_PROGRAM
      #     else
      #       if line.strip() == '' then
      #         program_lines << '' unless hide_next_program_fragment
      #       else
      #         program_lines << "\# #{line}".gsub("\\\'", "\'") unless hide_next_program_fragment
      #         state = IN_PARAGRAPH
      #       end
      #     end
      #   when IN_PROGRAM
      #     case line
      #     when /^(```|\{\: )/
      #       state = IN_DOCUMENT
      #       hide_next_program_fragment = false
      #       output_next_program_fragment_as_prose = false
      #     else
      #       line = line[4..]
      #       if output_next_program_fragment_as_prose then
      #         print "here"
      #         print "line: #{line}"
      #         if line.strip() == '' then
      #           program_lines << ''
      #         else
      #           program_lines << "\# #{line}"
      #         end
      #       elsif !hide_next_program_fragment
      #         current_program_line++
      #         line_map[current_program_line] = i
      #
      #         program_lines << line
      #       end
      #     end
      #   when IN_PARAGRAPH
      #     if line.strip() == '' then
      #       program_lines << '' unless hide_next_program_fragment
      #       state = IN_DOCUMENT
      #       hide_next_program_fragment = false
      #     else
      #       program_lines << "\# #{line}".gsub("\\\'", "\'") unless hide_next_program_fragment
      #     end
      #   end
      # }
      program = program_lines.join("\n")
      return program
    end

    def parse_markdown(document)
      # assume the default markdown renderer (kramdown)
      parsed_document = ::Kramdown::Document.new(document, {'html_to_native' => true, :input => 'GFM'})
      return parsed_document
    end

    def process_markdown(document)
      parsed_document = parse_markdown(document)
      new_root = each_image(parsed_document.root) { |image|
        alt_text = image.attr['alt']
        url = File.join(@site_url, image.attr['src'])
        ::Kramdown::Element.new(:text, "(See image at #{url}. Image description: #{alt_text})")
      }
      new_root = each_of_type(:comment, new_root) { |comment|
        }
      link_note = ::Kramdown::Element.new(:p)
      link_note.children << ::Kramdown::Element.new(:text, '(The URLs corresponding to the numbered link references can be found at the end of this file.)')
      new_root.children.unshift(link_note)
      parsed_document.root = new_root
      parsed_document.to_remove_html_tags
      parsed_document.to_kramdown
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

    def traverse(root, actions, lines = nil)
      if lines == nil then
        lines = []
      end

      if !(actions.has_key?(root.type)) then
        if root.children then
          root.children.each { |child| traverse(child, actions, lines) }
        else
          lines << root.value
        end
      else
        line = actions[root.type].(root)
        lines << line unless line == nil
      end
      return lines
    end

    def inline_traverse(root, actions)
      if root.is_a? String then
        root
      elsif !(actions.has_key?(root.type)) then
        root.value
      else
        actions[root.type].(root)
      end
    end

    def each_image(root, &replacer)
      root = root.dup
      if root.type == :img then
        replacer.(root)
      else
        root.children.each_with_index { |child, i|
          root.children[i] = each_image(child, &replacer)
        }
        root
      end
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
  end
end
