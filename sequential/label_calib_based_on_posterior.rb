#! /bin/env ruby


###########################################
require 'getoptlong'
require 'bio'

require_relative 'rrtc/do_rrtc.rb'


###########################################
infile = nil
calib_file = nil
type = nil
is_output_numbered_tree = false


###########################################
def read_calib_file(calib_file)
  node_name_2_paras = Hash.new
  in_fh = File.open(calib_file)
  in_fh.each_line do |line|
    line.chomp!
    next if not line =~ /^t_n\d+/
    line_arr = line.split("\t")
    node_name = line_arr[0]
    node_name.sub!('t_n', '')
    paras = line_arr[1, 100]
    node_name_2_paras[node_name] = paras
  end
  in_fh.close
  return(node_name_2_paras)
end


###########################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--calib', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--output_numbered_tree', GetoptLong::NO_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--calib'
      calib_file = value
    when '-t'
      type = value
    when '--output_numbered_tree'
      is_output_numbered_tree = true
  end
end


###########################################
tree = read_mcmctree_out(infile)

if is_output_numbered_tree
  puts tree.cleanNewick(is_remove_quote = true)
  exit
end


###########################################
node_name_2_paras = read_calib_file(calib_file)


###########################################
tree.internal_nodes.each do |node|
  node.bootstrap_string = %w[" "].join(node_name_2_paras[node.bootstrap.to_s].join(','))
  #node.bootstrap_string = [' ', ' '].join(node.bootstrap_string)
end

tree.allTips.each do |tip|
  tip.name.gsub!(/\"/, "")
end

puts tree.cleanNewick(is_remove_quote = true).gsub('"', "'")

# sed 's/"G(/ "G(/g; s/"SN(/ "SN(/g; s/"ST(/ "ST(/g; s/)"/)" /g; '


