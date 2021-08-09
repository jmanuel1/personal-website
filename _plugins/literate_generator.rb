require 'digest'

IN_DOCUMENT = 0
IN_PROGRAM = 1
IN_FRONTMATTER = 2

module Jekyll
  class LiteratePostGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
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
      program_content = post_to_program(post_content)
      hash = Digest::SHA256.hexdigest post_content
      output_dir = File.join(site.source, ".literate-output")
      output_path = File.join(site.source, ".literate-output/#{hash}.py")
      print "Writing generated code to #{output_path}\n"
      Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
      File.write(output_path, program_content, { mode: 'w' })
      result = { dir: ".literate-output", name: "#{hash}.py" }
    end

    def post_to_program(document)
      program_lines = []

      state = IN_DOCUMENT
      hide_next_program_fragment = false
      was_in_frontmatter = false
      output_next_program_fragment_as_prose = false
      current_program_line = 0

      line_map = {}
      document_lines = document.split("\n")

      document_lines.each_with_index { |line, i|
        case state
        when IN_DOCUMENT
          case line
          when /^```python/
            state = IN_PROGRAM
          when /^<!--\s*hide\s*-->/
            hide_next_program_fragment = true
          when /^<!--\s*output_as_prose\s*-->/
            output_next_program_fragment_as_prose = true
          when /^---$/
            unless was_in_frontmatter
              state = IN_FRONTMATTER
              was_in_frontmatter = true
            end
          else
            program_lines << "\# #{line}"
          end
        when IN_PROGRAM
          case line
          when /^```/
            state = IN_DOCUMENT
            hide_next_program_fragment = false
            output_next_program_fragment_as_prose = false
          else
            if output_next_program_fragment_as_prose then
              print "here"
              print "line: #{line}"
              if line.strip() == '' then
                program_lines << ''
              else
                program_lines << "\# #{line}"
              end
            elsif !hide_next_program_fragment
              current_program_line++
              line_map[current_program_line] = i

              program_lines << line
            end
          end
        when IN_FRONTMATTER
          case line
          when /^---$/
            state = IN_DOCUMENT
          end
        end
      }
      program = program_lines.join("\n")
      return program
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
