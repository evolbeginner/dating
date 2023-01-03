#! /usr/bin/env ruby


#############################################################
require 'getoptlong'
require 'bio-nwk'

require 'colorize'


#############################################################
<<EOF
class Bio::Tree
  def getNameTipRela()
    tip2name, name2tip = [Hash.new, Hash.new]
    allTips.each do |tip|
      tip2name[tip] = tip.name
      name2tip[tip.name] = tip
    end
    return([name2tip, tip2name])
  end

  def getNameNodeRela()
    node2name, name2node = [Hash.new, Hash.new]
    nodes.each do |node|
      node2name[node] = node.name
      name2node[node.name] = node
    end
    return([name2node, node2name])
  end
end
EOF


#############################################################
def get_calib(file, tree)
  calibs = Hash.new
  in_fh = File.open(file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    if line_arr.size >= 3
      calibs[line_arr[0,2]] = line_arr[-1].to_f
    elsif line_arr.size == 2
      calibs[line_arr[0,2]] = nil
    elsif line_arr.size == 1
      if line_arr[0] == 'root'
        calibs[tree.twoTaxaNode(tree.root).map{|i|i.name}] = nil
      end
    end
  end
  in_fh.close
  return(calibs)
end


#############################################################
tree_file = nil
calib_file = nil
range = 1
is_minmax = true
is_min = false
is_max = false


#############################################################
opts = GetoptLong.new(
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['-c', GetoptLong::REQUIRED_ARGUMENT],
  ['--range', GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '--ref'
      timetree_file = value
    when '-t'
      tree_file = value
    when '-c'
      calib_file = value
    when '--range'
      range = value.to_f
  end
end


#############################################################
tree = getTreeObjs(tree_file)[0]

calibs = get_calib(calib_file, tree)

name2node, node2name = tree.getNameNodeRela

calibs.each_pair do |names, v|
  nodes = names.kind_of?(Array) ? names.map{|i|name2node[i]} : ['root']
  if nodes[0] == 'root'
    lca = tree.root
  else
    lca = tree.lowest_common_ancestor(nodes[0], nodes[1])
  end
  real_age = tree.distance(lca, nodes[0])
  range2 = v.nil? ? range : v # note range may be replaced by v (the last col specified in the file calib)
  min = ((1-range2)*real_age).round(3)
  max = ((1+range2)*real_age).round(3)
  if is_minmax
    calib = ['>', min, '<', max].map(&:to_s).join('')
  elsif is_min
    calib = ['>', min].map(&:to_s).join('')
  elsif is_max
    calib = ['<', max].map(&:to_s).join('')
  end
  lca.name = calib
end

output = tree.cleanNewick

if output =~ /\);$/
  output.sub!('(', '')
  output.sub!(');', ';')
end
puts output

STDERR.puts "range is #{range}".colorize(:red)


