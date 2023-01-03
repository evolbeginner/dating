#! /usr/bin/env ruby


#######################################################
require 'getoptlong'

require 'util'


#######################################################
infile = nil

clade_time = Hash.new{|h,k|h[k]={}}


#######################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
  end
end


#######################################################
topo = 1
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  if line =~ /^$/
    topo += 1
    next
  end

  line_arr = line.split("\t")
  if line_arr.size == 1
    next
  end

  clade = getCorename(line_arr[0])
  clade_time[clade][topo] = line_arr[1,3].map{|i|i.to_f}
end
in_fh.close


#######################################################
puts %w[class cat mean min max].join("\t")
clade_time.each_pair do |clade, v|
#a	Set1	508.2	187.9	833.1
  v.each_pair do |topo, times|
    puts [clade, "Topo"+topo.to_s, times].flatten.join("\t")
  end
end


