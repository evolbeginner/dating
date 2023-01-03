#! /bin/env ruby


###########################################################
require 'getoptlong'
require 'bio'
require 'bio-nwk'

require 'SSW_math'


###########################################################
infile = nil
n = 100000
type = 'uniform'


###########################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-n', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', '--type', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-n'
      n = value.to_i
    when '-t', '--type'
      type = value
  end
end



###########################################################
#node.bootstrap_string = '>10<15' unless node.isTip?(tree)


###########################################################
tree = getTreeObjs(infile)[0]

tree.internal_nodes.sample(n).each do |node|
  next if node.bootstrap_string.nil?
  min, max = node.bootstrap_string.split('-').map(&:to_f)
  case type
    when 'uniform'
      node.bootstrap_string = ['>', min, '<', max].join('')
    when 'norm'
      mean = (min+max)/2
      sd = ((max+min)/2-min)/2
      alpha, beta = from_norm_to_gamma(mean, sd).map{|i|i.round(4)}
      node.bootstrap_string = ['G', '(', alpha, ',', beta, ')'].join('')
      node.bootstrap_string = %w[' '].join(node.bootstrap_string)
      #G(a, b)
  end
end

tree.each_edge do |node0, node1, edge|
  edge.distance = nil
end

puts tree.cleanNewick(is_remove_quote=false)


