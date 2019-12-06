require 'json'

links = []
nodes = []

define_method :added? do |number|
  nodes.find { |e| e[:name] == number.to_s }
end

define_method :add_node do |number, from, fromIndex|
  if added? number or number > 30
    return
  end
  index = nodes.length
  nodes << { group: 1, name: number.to_s }
  links << { source: fromIndex, target: index, value: 50 } unless from == nil
  add_node number*2, number, index
  if (number - 1) % 3 == 0 && (number - 1) % 2 != 0
    add_node (number - 1)/3, number, index
  end
end

add_node 1, nil, -1

File.open "assets/collatz.json", "w" do |file|
  file << JSON.generate({ links: links, nodes: nodes })
end
