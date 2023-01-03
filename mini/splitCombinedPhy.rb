#! /usr/bin/env ruby


#######################################################################
require 'getoptlong'


#######################################################################
infile = nil
num = 1
min = 0
gene_nums = Array.new


#######################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-n', GetoptLong::REQUIRED_ARGUMENT],
  ['--min', GetoptLong::REQUIRED_ARGUMENT],
  ['-g', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-n'
      num = value.to_i
    when '--min'
      min = value.to_i
    when '-g'
      if value =~ /[-]/
        value.split('-')[0].to_i.upto(value.split('-')[1].to_i).each do |i|
          gene_nums << i
        end
      elsif value =~ /,/
        gene_nums << value.split(',').map{|i|i.to_i}
      end
  end
end


gene_nums.flatten!


#######################################################################
count = 0
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  if line =~ /(\d+)\s+\d+$/
    count += 1
  end
  break if count > num
  next unless gene_nums.include?(count) unless gene_nums.empty?
  puts line
end


