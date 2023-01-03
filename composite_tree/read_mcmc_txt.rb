#! /usr/bin/env ruby


################################################
require 'getoptlong'
require 'parallel'


################################################
infiles = Array.new
cpu = 1


################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-n', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infiles << value
    when '-n'
      cpu = value.to_i
  end
end


################################################
res = Parallel.map(infiles, in_processes:cpu) do |infile|
  indices = []
  outs = []
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    if $. == 1
      line_arr.each_with_index do |item, index|
        indices << index if item =~ /^t_n\d+$/
      end
    end
    outs << indices.map{|i|line_arr[i]}
  end
  in_fh.close
  outs.pop
  outs
end


################################################
res.each_with_index do |outs, index|
  if index > 0
    outs.shift
  end
  puts outs.map{|arr|arr.join("\t")}.join("\n")
end


