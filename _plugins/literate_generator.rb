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
        p post.data
        print "\n"
        if post.data.fetch("literate", false) then
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
      current_program_line = 0

      line_map = {}
      document_lines = document.split("\n")
      # puts document_lines.inspect
      document_lines.each_with_index { |line, i|
        # puts line
        # puts state
        case state
        when IN_DOCUMENT
          case line
          when /^```python/
            state = IN_PROGRAM
            # puts 'enter IN_PROGRAM'
          when /^<!--\s*hide\s*-->/
            hide_next_program_fragment = true
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
          else
            unless hide_next_program_fragment
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
