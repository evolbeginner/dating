#! /bin/env ruby


##################################################
require 'getoptlong'


##################################################
infile = nil #out
mcmctxt_file = nil


##################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--mcmctxt', GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--mcmctxt'
      mcmctxt_file = value
  end
end


##################################################
get_branch_num(infile)
Species tree for FigTree.  Branch lengths = posterior mean times; 95% CIs = labels


