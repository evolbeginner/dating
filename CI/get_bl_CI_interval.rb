#! /usr/bin/env ruby


#################################################
$DIR = File.dirname($0)
$: << File.join($DIR, 'lib')


#################################################
require 'getoptlong'
require 'bio'

require 'tree'


#################################################
infile = nil
is_minmax = false
multiply = 1


#################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--minmax', GetoptLong::NO_ARGUMENT],
  ['--multiply', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--minmax'
      is_minmax = true
    when '--multiply'
      multiply = value.to_f
  end
end


#################################################
tree = getTreeObjs(infile).shift

a_tip = tree.allTips[0]

total_dist = tree.distance(tree.root, a_tip)


tree.internal_nodes.each do |node|
  dist = total_dist - tree.distance(tree.root, node)
  node_names = tree.twoTaxaNode(node).map{|i|i.name.gsub(' ', '_')}
  node_name = node_names.join('|')
  ci_interval = node.name.split('-').reverse.map{|i|i.to_f}.reduce(:-).round(3)
  ci_output = is_minmax ? node.name.split('-').map{|i|i.to_f.round(3)} : ci_interval
  node_name = node_name.size >= 90 ? node_name.split('|').map{|i|i[0,30]}.join('|') : node_name
  #node_name = node_name.size >= 90 ? node_name[0,30] : node_name
  puts [node_name, [dist.round(3), ci_output].flatten.map{|i|i*multiply}].flatten.join("\t")
end


