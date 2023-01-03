#! /usr/bin/env ruby


#########################################################################
require 'getoptlong'


#########################################################################
infile = nil


#########################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
  end
end


#########################################################################
is_analyze = false

in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  #if line =~ /^Posterior mean \(95% credibility interval\)/
  #if line =~ /^Posterior mean \(95% Equal\-tail CI\) \(95% HPD CI\) HPD-CI-width/
  if line =~ /^Posterior means? \(95% Equal\-tail CI\) \(95% HPD CI\) HPD-CI-width/
    is_analyze = true
    next
  end
  if line =~ /^mu/
    is_analyze = false
    break
  end
  #t_n143    10.9042 (9.2079, 12.6721) (9.1353, 12.5684)  (Jeffnode 72)
  if is_analyze
    next if line =~ /^$/
    bl = line.split(/\s+/)[1].to_f
    if line =~ /\(([ ]?\S+),[ ]+(\S+)\)/
      ci = $2.to_f - $1.to_f
    end
    puts [bl, ci].join("\t")
  end
end
in_fh.close


