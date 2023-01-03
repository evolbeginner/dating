#! /usr/bin/env ruby


########################################################
require 'getoptlong'


########################################################
infile = nil


########################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
  end
end


########################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  line.gsub!(/\d(\.\d+)? e[-] \d+/x, $&.to_f.to_s)
  puts line
  break
end
in_fh.close


