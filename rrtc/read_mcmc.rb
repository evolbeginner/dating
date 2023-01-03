#! /bin/env ruby


####################################################
require 'csv'    
require 'getoptlong'


####################################################
infile = nil
outfile = nil
nodes = Array.new

indices = Array.new


####################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-o', GetoptLong::REQUIRED_ARGUMENT],
  ['--nodes', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-o'
      outfile = value
    when '--nodes'
      value.split(',').map{|i|nodes << i.split(/[|-]/)}
  end
end


nodes.map!{|a,b| ['t_n'+a,'t_n'+b] }


####################################################
table = CSV.table(infile, :headers => true, col_sep: "\t")
table.delete_if do |row|
  #nodes.any?{|a, b| row[a.to_sym] > row[b.to_sym] }
  nodes.select{|a, b| row[a.to_sym] > row[b.to_sym] }.size >= 0.2 * nodes.size
end

File.open(outfile, 'w') do |f|
  f.write(table.to_csv(:col_sep => "\t"))
end


