#! /bin/env ruby


######################################################################################
require 'getoptlong'

require 'bio-nwk'


######################################################################################
infile = nil
divided_by = 1


######################################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--divided_by', GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--divided_by'
      divided_by = value.to_i
  end
end


######################################################################################
tree = getTreeObjs(infile)[0]

tree.internal_nodes.each do |node|
  next if node.name !~ /[><]/

  min, max = [0, nil]
  node.name.gsub!(/[']/, '')
  if node.name =~ /< ([0-9.]+)/x
    max = $1.to_f
  end
  if node.name =~ /> ([0-9.]+)/x
    min = $1.to_f
  end

  if max.nil?
    max = 1.1 * min
  end

  ave = (min+max)/2/divided_by
  #puts [node.name, ave, min, max].join("\t")

  node.name = '@'+ave.to_s
end


puts tree.cleanNewick()


