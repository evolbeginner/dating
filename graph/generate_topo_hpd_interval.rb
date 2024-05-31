#! /usr/bin/env ruby


#######################################################
require 'getoptlong'

require 'util'


#######################################################
infile = nil
is_rev = false

clade_time = Hash.new{|h,k|h[k]={}}


#######################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--rev', '-r', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--rev', '-r'
      is_rev = true
  end
end


#######################################################
topo = 1
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  if line =~ /^$/
    if ! is_rev
      topo += 1
    end
    next
  end

  line_arr = line.split("\t")
  if line_arr.size == 1
    if is_rev
      topo = line
    end
    next
  end

  clade = getCorename(line_arr[0])
  if ! is_rev
    clade_time[clade][topo] = line_arr[1,3].map{|i|i.to_f}
  else
    clade_time[topo][clade] = line_arr[1,3].map{|i|i.to_f}
  end
end
in_fh.close


#######################################################
puts %w[class cat mean min max].join("\t")
clade_time.each_pair do |clade, v|
#a	Set1	508.2	187.9	833.1
  v.each_pair do |topo, times|
    puts [clade, topo.to_s, times].flatten.join("\t")
  end
end


