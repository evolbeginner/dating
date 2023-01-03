#! /bin/env ruby


###############################################################
require 'getoptlong'
require 'bio'
require 'bio-nwk'

require 'nwk'


###############################################################
def delete_all_calibs(tree, is_delete_root_calib)
  tree.internal_nodes.each do |node|
    if node == tree.root
      node.name = is_delete_root_calib ? '' : node.name
    else
      node.name = ''
    end
  end
  return(tree)
end


def get_max_age(tree)
  if tree.root.name =~ /<(.+)/ or tree.root.name =~ /B\(/
    return($1)
  else
    STDERR.puts "#{$a} Root max is not defined! Exiting ......"
    exit 1
  end
end


def get_name_to_tip(tree)
  name2tip = Hash.new
  tree.allTips.each do |tip|
    name2tip[tip.name] = tip
  end
  return(name2tip)
end


def bootstrap_to_unif(tree, probs, is_stringent, is_cauchy=false)
  root_max = get_max_age(tree)
  tree.internal_nodes.each do |node|
    if is_cauchy
      if node.name =~ />(.+)/
        node.name = ">" + $1
      end
    else
      if node.name =~ />(.+)<(.+)/
        node.name = '"B(' + [$1, $2, probs[0], probs[1]].join(',') + ')"'
      elsif node.name =~ /^<(.+)/
        node.name = '"B(' + [0, $1, 0, probs[1]].map(&:to_s).join(',') + ')"'
      elsif node.name =~ /^>(.+)/ and is_stringent
        node.name = '"B(' + [$1, root_max, probs[0], probs[1]].map(&:to_s).join(',') + ')"'
      end
    end
  end
  return(tree)
end


def read_calib(infile)
  node2calib = Hash.new
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    next if line =~ /^$/
    line_arr = line.split("\t")
    otus = line_arr[0,2].map{|i|i.gsub('_', ' ')} # "_" to space
    calib = line_arr[2]
    node2calib[otus] = calib
  end
  in_fh.close
  return(node2calib)
end


def add_new_calib(tree, calib_file)
  internal_nodes = tree.internal_nodes

  name2tip = get_name_to_tip(tree)

  node2calib = read_calib(calib_file)
  node2calib.each_pair do |otus, calib|
    node1, node2 = otus.map{|i|name2tip[i]}
    lca = tree.lowest_common_ancestor(node1, node2)

    next if otus.any?{|otu| otu =~ /^#/}

    if lca.nil?
      STDERR.puts "OTUs #{otus.join("\t")} not found!"
      next
    end
    if calib =~ /[#]/
      lca.name = ""
    else
      lca.name = calib
    end
  end

  return(tree)
end


###############################################################
infile = nil
is_stringent = false
is_cauchy = false
calib_file = nil

is_delete_all_calibs = false
is_delete_root_calib = false
is_mcmctree = false

is_unif = false
probs = Array.new


###############################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--unif', GetoptLong::REQUIRED_ARGUMENT],
  ['--stringent', GetoptLong::NO_ARGUMENT],
  ['--cauchy', GetoptLong::NO_ARGUMENT],
  ['--calib', GetoptLong::REQUIRED_ARGUMENT],
  ['--del_all', '--del_all_calibs', '--delete_all_calibs', GetoptLong::NO_ARGUMENT],
  ['--del_root', '--del_root_calib', '--delete_root_calib', GetoptLong::NO_ARGUMENT],
  ['--mcmctree', GetoptLong::NO_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--unif'
      is_unif = true
      probs = value.split(',')
    when '--stringent'
      is_stringent = true
    when '--cauchy'
      is_cauchy = true
    when '--calib'
      calib_file = value
      $a = calib_file
    when '--del_all', '--del_all_calibs', '--delete_all_calibs'
      is_delete_all_calibs = true
    when '--del_root', '--del_root_calib', '--delete_root_calib'
      is_delete_all_calibs = true
      is_delete_root_calib = true
    when '--mcmctree'
      is_mcmctree = true
  end
end


###############################################################
if not is_mcmctree
  tree = getTreeObjs(infile)[0]
else
  #first_line = `head -1 #{infile}`.chomp
  first_line, tree = getTreeObjFromMcmctree(infile)
end

if is_delete_all_calibs
  tree = delete_all_calibs(tree, is_delete_root_calib)
end

unless calib_file.nil?
  tree = add_new_calib(tree, calib_file)
end

if is_unif
  tree = bootstrap_to_unif(tree, probs, is_stringent, is_cauchy)
end


###############################################################
get_max_age(tree) # check if max age of the root is present!

puts first_line if is_mcmctree
puts tree.cleanNewick


