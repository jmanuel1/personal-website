list = STDIN.read
list.gsub!(/^-+/m) do |bullet|
  "  " * (bullet.length - 1) + "-"
end
puts list
