document = File.read(ARGV[0])
program_lines = []

IN_DOCUMENT = 0
IN_PROGRAM = 1
state = IN_DOCUMENT
hide_next_program_fragment = false
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
  end
}
program = program_lines.join("\n")
pid = Process.spawn("py", "-3", "-c", program, :in=>:in)
Process.wait(pid)
# TODO: Change line numbers in error messages
# puts output.gsub(/line (\d+)/) { |match|
#   puts "line match"
#   "line #{line_map[$1.to_int]}"
# }
