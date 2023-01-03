#! /usr/bin/env ruby


##################################################################
require 'getoptlong'
require 'csv'
#require 'basic/stats'
require 'statsample'
require 'bio'
require 'bio-nwk'

require 'Dir'
require 'util'


##################################################################
START_STR=
<<EOF
************
Species tree
ns = 86  nnode = 171
 father   node  name                                                         time     sons          fossil
EOF

#FATHER_STR = 'father   node  name                                                         time     sons          fossil'
FATHER_STR = ' father   node  name'


##################################################################
infile = nil
tree_indir = nil
mcmc_infile = nil
is_output_node_taxon = false

treeName2nodeNames = Hash.new{|k,v|k[v]=[]}
nodeName2treeName = Hash.new
gene2treeName2rates = Hash.new{|k1,v1|k1[v1]=Hash.new{|k2,v2|k2[v2]=[]}}
treeName2gene2rates = Hash.new{|k1,v1|k1[v1]=Hash.new{|k2,v2|k2[v2]=[]}}


##################################################################
class NODE
  attr_accessor :pname, :cname, :name, :node_name, :taxon
  def initialize(line_arr)
    #    97      1  Acidiphilium_angustum_ATCC_35903                             0.00000
    #    170    171                                                               3.00214  (83 84)
    @pname, @name = line_arr[1,2]
    if line_arr[4] == '0.00000'
      @taxon = line_arr[3]
      is_tip?
    end
    @node_name = @name
  end
  def is_tip?
    return @taxon =~ /\w/ ? true : false
  end
end


##################################################################
def parse_mcmctree_final(infile)
  is_start = false
  name2node = Hash.new
  pname2cname = Hash.new{|h,k|h[k]=[]}
  cname2pname = Hash.new

  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split(/[ ]+/)
    if line =~ /#{FATHER_STR}/
      is_start = true
      next
    end
    if is_start
      if line =~ /^$/
        break
      else
        node = NODE.new(line_arr)
        pname2cname[node.pname] << node.name
        cname2pname[node.name] = node.pname
        name2node[node.name] = node
      end
    end
  end
  in_fh.close
  return([pname2cname, cname2pname, name2node])
end


def get_pc(name2node, root=nil)
  p2c = Hash.new{|h,k|h[k]=[]}
  c2p = Hash.new
  name2node.each_pair do |node_name, node|
    pname = node.pname; p = name2node[pname]
    p = root if p.nil?
    c2p[node] = p
    p2c[p] << node
  end
  return([c2p, p2c])
end


def getNodeTaxonStrs(tree_infiles)
  tree2nodeTaxonStrs = Hash.new
  nodeTaxonStr2tree = Hash.new

  tree_infiles.each do |tree_infile|
    c = getCorename(tree_infile)
    nodeTaxonStrs = retrieve_all_internal_nodes(tree_infile)
    tree2nodeTaxonStrs[c] = nodeTaxonStrs
    nodeTaxonStrs.map{|i|nodeTaxonStr2tree[i]=c}
  end
  return([tree2nodeTaxonStrs, nodeTaxonStr2tree])
end


def get_all_tips(node, p2c)
  all_tips = Array.new

  return([node]) if node.is_tip?

  children = p2c[node]
  children.each do |i|
    if i.is_tip?
      all_tips << i
    else
      all_tips << get_all_tips(i, p2c)
    end
  end
  return(all_tips.flatten)
end


def get_two_taxon_str(node, p2c)
  all_tips = Array.new
  if p2c.include?(node)
    children = p2c[node]
    tips = Array.new # [[], []]
    children.each do |child|
      tips << get_all_tips(child, p2c)
    end
  else
    tips = [[node]]
  end

  two_taxon_str = tips.map{|arr|arr.sort_by{|i|i.taxon}[0].taxon}.sort.join('|')
  return(two_taxon_str)
end


def retrieve_all_internal_nodes(tree_infile)
  nodeTaxonStrs = Array.new
  tree = getTreeObjs(tree_infile).shift
  int_nodes = tree.internal_nodes
  int_nodes.each do |internal_node|
    nodeTaxonStrs << tree.tips(internal_node).map{|tip|(tip.name).gsub(' ','_')}.sort.join("|")
  end
  nodeTaxonStrs << tree.allTips
  nodeTaxonStrs.flatten!
  return(nodeTaxonStrs)
end


##################################################################
root = NODE.new([])
root.pname = nil
root.name = '0'
root.node_name = root.name


##################################################################
if __FILE__ == $0
  opts = GetoptLong.new(
    ['-i', GetoptLong::REQUIRED_ARGUMENT],
    ['--tree_indir', GetoptLong::REQUIRED_ARGUMENT],
    ['-m', GetoptLong::REQUIRED_ARGUMENT],
    ['--output_node_taxon', GetoptLong::NO_ARGUMENT],
  )


  opts.each do |opt, value|
    case opt
      when '-i'
        infile = value
      when '--tree_indir'
        tree_indir = value
      when '-m'
        mcmc_infile = value
      when '--output_node_taxon'
        is_output_node_taxon = true
    end
  end


  ##################################################################
  pname2cname, cname2pname, name2node = parse_mcmctree_final(infile)

  c2p, p2c = get_pc(name2node, root)

  if is_output_node_taxon
    name2node.each do |node_name, node|
      two_taxon_str = get_two_taxon_str(node, p2c)
      puts [node_name, two_taxon_str].join("\t")
    end
    exit
  end

  tree_infiles = read_infiles(tree_indir)
  tree2nodeTaxonStrs, nodeTaxonStr2tree = getNodeTaxonStrs(tree_infiles)


  ##################################################################
  p2c.each_pair do |p, children|
    next if p == root
    all_tips = get_all_tips(p, p2c)
    nodeTaxonStr = all_tips.map{|i|i.taxon}.sort.join('|')
    #puts [p.name, nodeTaxonStr2tree[nodeTaxonStr]].join("\t")
    if nodeTaxonStr2tree.include?(nodeTaxonStr)
      treeName = nodeTaxonStr2tree[nodeTaxonStr]
      treeName2nodeNames[treeName] << p.name
      children.each do |child|
        treeName2nodeNames[treeName] << child.name unless p2c.include?(child)
      end
    end
  end

  treeName2nodeNames.each do |treeName, a|
    a.each do |i|
      nodeName2treeName[i] = treeName
    end
  end


  ##################################################################
  # parse mcmc_infile
  csv = CSV.read(mcmc_infile, :headers=>true, :col_sep=>"\t")

  headers = CSV.open(mcmc_infile, 'r') { |csv| csv.first }.shift.split("\t")
  rate_headers = headers.select{|i|i=~/^r_g\d+_n\d+$/}

  rate_headers.each do |header|
    header =~ /^ r _ g(\d+) _ n(\d+) $/x
    gene = $1
    nodeName = $2
    if nodeName2treeName.include?(nodeName)
      treeName = nodeName2treeName[nodeName]
      a = csv[header]
      a.map!{|i|i.to_f}
      #a.extend(Basic::Stats)
      gene2treeName2rates[gene][treeName] << a.mean
      treeName2gene2rates[treeName][gene] << a.mean
    end
  end


  ##################################################################
  #gene2treeName2rates.each_pair do |gene, v1|
  #  puts v1.map{|treeName, rates|rates.mean}.join("\t")
  #end

  puts treeName2gene2rates["Alpha-noRick"].values.map{|i|i.mean}.join("\t")
  puts treeName2gene2rates["Rick"].values.map{|i|i.mean}.join("\t")
  puts treeName2gene2rates["Cyano"].values.map{|i|i.mean}.join("\t")
  puts %w[Euk Euk-plant].map{|i|treeName2gene2rates[i].values}.flatten(1).map{|i|i.mean}.join("\t")
  #puts %w[Rick Euk Euk-plant].map{|i|treeName2gene2rates[i].values}.flatten(1).size.map{|i|i.mean}.join("\t")

end


