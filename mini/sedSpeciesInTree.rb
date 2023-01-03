#! /usr/bin/env ruby


######################################################
require 'getoptlong'


######################################################
tree_file = nil
infile1 = nil
infile2 = nil


######################################################
opts = GetoptLong.new(
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--i1', GetoptLong::REQUIRED_ARGUMENT],
  ['--i2', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-t'
      tree_file = value
    when '--i1'
      infile1 = value
    when '--i2'
      infile2 = value
  end
end


######################################################
#a = Regexp.new('\(.+Methylobacterium_sp_Leaf361.+Meganema_perideroedes_DSM_15528\)\)');
a = `cat #{infile1}`.chomp
b = `cat #{infile2}`.chomp


######################################################
in_fh = File.open(tree_file, 'r')
in_fh.each_line do |line|
  line.chomp!
  if $. == 1
    #line = "213\t1"
    ;
  elsif $. == 2
    line.gsub!(a, b)
  end
  puts line
end

in_fh.close


