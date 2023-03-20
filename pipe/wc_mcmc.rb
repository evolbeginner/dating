#! /bin/env ruby


##################################################
require 'getoptlong'
require 'parallel'
require 'find'

require 'processbar'


##################################################
indir = nil
include_bs = Array.new
cpu = 4

include_fs = Array.new
file_to_wc = Hash.new


##################################################
if __FILE__ == $0
  opts = GetoptLong.new(
    ['--indir', GetoptLong::REQUIRED_ARGUMENT],
    ['--include_b', GetoptLong::REQUIRED_ARGUMENT],
    ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  )

  opts.each do |opt, value|
    case opt
      when '--indir'
        indir = value
      when '--include_b'
        include_bs << value.split(',')
        include_bs.flatten!
      when '--cpu'
        cpu = value.to_i
    end
  end


  ##################################################
  Find.find(indir) do |path|
    b = File.basename(path)
    next if not include_bs.include?(b)
    include_fs << path
  end

  count = Thread.new{
    while true;
      count = file_to_wc.size
      processbar(count, include_fs.size)
      sleep 2
    end 
  }   

  Parallel.map(include_fs, in_threads:cpu) do |infile_f|
    num_of_line = `wc -l #{infile_f}`.chomp.to_i
    file_to_wc[infile_f] = num_of_line
  end

  puts

  file_to_wc.sort.to_h.each do |file, wc|
    puts [file, wc].join("\t")
  end

end


