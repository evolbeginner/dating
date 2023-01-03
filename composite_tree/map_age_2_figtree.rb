#! /usr/bin/env ruby


###########################################
#test.rb


###########################################
require 'getoptlong'
require 'bio-nwk'

require 'util'


###########################################
infile = nil
age_file = nil

node2name = Hash.new
name2node = Hash.new


###########################################
def getAgeAndHpd(age_file)
  name2ages = Hash.new{|h,k|h[k]={}}
  in_fh = File.open(age_file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    twoTaxaNodeNameStr = line_arr[0]
    mean = line_arr[1].to_f
    min, max = line_arr[2,2].map{|i|i.to_f}
    name2ages[twoTaxaNodeNameStr][:mean] = mean
    name2ages[twoTaxaNodeNameStr][:min] = min
    name2ages[twoTaxaNodeNameStr][:max] = max
  end
  in_fh.close
  return(name2ages)
end


def output_in_nexus(tree)
  puts '#NEXUS'
  puts 'BEGIN TREES;'
  puts
  print "\tutree 1 = "
  output = tree.output_newick
  output.gsub!(/[\n\s]/, '')
  output.gsub!(/\'/, '')
  puts output
  puts 'END;'
end


###########################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-a', '--age', GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-a', '--age'
      age_file = value
  end
end


###########################################
tree = getTreeObjs(infile)[0]

tree.nodes.each_with_index do |node, index|
  name = [tree.twoTaxaNodeName(node)].join('|')
  #name = tree.twoTaxaNodeNameStr(node)
end

tree.internal_nodes.each do |node|
  #next if node == tree.root
  name = [tree.twoTaxaNodeName(node)].join('|')
  #name = tree.twoTaxaNodeNameStr(node)
  node2name[node] = name
  name2node[name] = node
end

name2ages = getAgeAndHpd(age_file)
tree.allTips.map{|tip|name2ages[tip.name.gsub(' ', '_')][:mean] = 0}


###########################################
tree.each_edge do |parent, child, edge|
  #child_age = haha(tree, child)
  parent_name = [tree.twoTaxaNodeName(parent)].join('|').gsub(' ', '_')
  #parent_name = tree.twoTaxaNodeNameStr(parent).gsub(' ', '_')
  child_name = [tree.twoTaxaNodeName(child)].join('|').gsub(' ', '_')
  #child_name = tree.twoTaxaNodeNameStr(child).gsub(' ', '_')
  edge.distance = name2ages[parent_name][:mean] - name2ages[child_name][:mean]
  parent.name = [' [&95%HPD={', name2ages[parent_name][:min], ',', name2ages[parent_name][:max], '}]'].map{|i|i.to_s}.join("")
end

output_in_nexus(tree)


