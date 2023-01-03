#! /usr/bin/env ruby


###################################################################
$: <<  File.expand_path("~/project/Rhizobiales/scripts/angst/")
$: <<  File.expand_path("~/project/Rhizobiales/scripts/angst/", 'lib')
DIR = File.dirname(__FILE__)


###################################################################
require 'getoptlong'
require 'bio'
require 'parallel'
require 'tempfile'
require 'bio-nwk'

require 'chang_yong'
require 'Dir'
require 'getSubtree'


###################################################################
FIGTREE2TREE = File.join(DIR, "figtree2tree.sh")
FLOATTREEBL = File.join(DIR, "float_tree_bl.rb")

treefiles = Array.new
species_tree_file = nil
is_tmpfile = false
cpu = 1
is_nwk = false

fams_included = Hash.new
taxa2fam = Hash.new{|h,k|h[k]={}}
fam2taxa = Hash.new{|h,k|h[k]={}}
lines = Array.new


###################################################################
def getTaxa2Node(tree)
  taxa2node = Hash.new
  tree.each_node do |node|
    taxa = getSortedTaxa(tree.tips(node), true, true, false)
    taxa2node[taxa] = node
  end
  return(taxa2node)
end


def getTaxaIncluded(treefiles)
  taxas = Array.new
  treefiles.each do |treefile|
    tree = getTreeObjs(treefile, 1).shift()
    taxa = getSortedTaxa(tree.tips(tree.root), true, true, false)
    taxas << taxa
  end
  return(taxas)
end


def getSortedTaxa(tips, is_space=true, is_remove_front_num=true, is_remove_end_num=true)
  tips = Marshal.load(Marshal.dump(tips))
  if is_space
    tips.map{|i|i.name.gsub!(' ', '_'); i.name}
  end
  if is_remove_front_num
    tips.map{|i|i.name.sub!(/^\d+\|/,''); i.name}
  end
  if is_remove_end_num
    tips.map{|i|i.name.sub!(/_\d+$/,''); i.name}
  end
  tips.sort_by!{|i|i.name}.map!{|i|i.name}
  return(tips)
end


###################################################################
if __FILE__ == $0
  opts = GetoptLong.new(
    ['-t', GetoptLong::REQUIRED_ARGUMENT],
    ['--species_tree', GetoptLong::REQUIRED_ARGUMENT],
    ['--tmpfile', GetoptLong::NO_ARGUMENT],
    ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
    ['--nwk', GetoptLong::NO_ARGUMENT],
  )


  opts.each do |opt, value|
    case opt
      when /^-t$/
        treefiles << value.split(',')
      when /^--species_tree$/
        species_tree_file = value
      when /^--tmpfile$/
        is_tmpfile = true
      when /^--cpu$/
        cpu = value.to_i
      when /^--nwk$/
        is_nwk = true
    end
  end


  ###################################################################
  treefiles.flatten!


  ###################################################################
  if is_tmpfile
    tmpfile = Tempfile.new('foo')
    if is_nwk
      `cp #{species_tree_file} #{tmpfile.path}`
    else
      `bash #{FIGTREE2TREE} #{species_tree_file} > #{tmpfile.path}`
    end
    #`bash #{FIGTREE2TREE} #{species_tree_file} > #{tmpfile}`
    `ruby #{FLOATTREEBL} -i #{tmpfile.path} | sponge #{tmpfile.path}`
    species_tree_file = tmpfile.path
  end

  species_tree = getTreeObjs(species_tree_file).shift()

  taxa2node = getTaxa2Node(species_tree)
  #taxa2node.each_pair do |taxa, v|
  #  puts taxa if taxa.count{|i|i=~/Methylobacterium/} == 9
  #end

  taxas = getTaxaIncluded(treefiles).sort

  taxas.each do |taxa|
    if taxa2node.include?(taxa)
      node = taxa2node[taxa]
      a = node.name.split('-')
      min, max = a.map{|i|i.to_f}
      mean = species_tree.distance(node, species_tree.tips(node)[0])
      #puts [start, stop, height].join("\t")
      puts [mean, min, max].join("\t")
    end
  end

end

<<EOF
taxa2node.each_pair do |taxa, node|
  if taxas.include?(taxa)
    a = node.name.split('-')
    start, stop = a.map{|i|i.to_f}
    height = species_tree.distance(node, species_tree.tips(node)[0])
    puts [taxas.index(taxa), start, stop, height].join("\t")
  end
end
EOF


