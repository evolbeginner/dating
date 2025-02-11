#! /usr/bin/env ruby


#################################################################
require 'getoptlong'
require 'parallel'

require 'Dir'
require 'SSW_bio'
require 'bio-nwk'


#################################################################
def get_ndata(seqfile)
  ndata = 0
  in_fh = File.open(seqfile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    if line =~ /^\s+\d+\s+\d+$/
      ndata += 1
    end
  end
  in_fh.close
  return(ndata)
end


def sprintf_argu_line(a, b, n=14)
  str = [sprintf('%'+n.to_s+'s', a), b].join(' = ')
  return(str)
end


def prepare_paml_ctl(ctl_file, outdir, h)
  dones = Hash.new
  lines = Array.new

  in_fh = File.open(ctl_file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    if line =~ /^\s* (\w+) \s* = /x
      if h.include?($1)
        line = sprintf_argu_line($1, h[$1], 14)
        dones[$1] = ''
      end
    end
    lines << line
  end
  in_fh.close
  `rm -rf #{ctl_file}`

  (h.keys - dones.keys).each do |i|
    lines << sprintf_argu_line(i, h[i], 14)
  end

  out_fh = File.open(ctl_file, 'w')
  out_fh.puts lines.join("\n")
  out_fh.close
end


#################################################################
def get_taxa_from_full_species_tree(treefile)
  tree = nil
  in_fh = File.open(treefile, 'r')
  in_fh.each_line do |line|
    next if $. != 2
    line.chomp!
    tree = Bio::Newick.new(line).tree
  end
  in_fh.close
  return(tree.allTips)
end


def get_root_age(treefile)
  tree = nil
  in_fh = File.open(treefile, 'r')
  in_fh.each_line do |line|
    next if $. != 2
    line.chomp!
    tree = Bio::Newick.new(line).tree
  end
  in_fh.close
  return(tree.root.name)
end


def set_root_age_and_output_tree(treefile2, root_age, outfile)
  tree2 = getTreeObjs(treefile2)[0]
  tree2.root.name = root_age
  out_fh = File.open(outfile, 'w')
  out_fh.write(tree2.output_newick)
  out_fh.close
end


#################################################################
$PWD = Dir.getwd
DIR = File.dirname($0)


#################################################################
PAML_DIR = File.expand_path("~/software/phylo/paml/v4.7")

PROG = File.join(PAML_DIR, 'bin', 'codeml')
CTL = File.join(DIR, 'codeml4CalculateSubRate.ctl')
AA_RATE_FILE = File.join(PAML_DIR, 'dat', 'lg.dat')

GET_MAP_FROM_PHYLIP = File.join(DIR, 'get_map_from_phylip.sh')


#################################################################
indir = nil
treefile = nil
outdir = nil
is_prot = true
is_nucl = false
cpu = 1
is_force = false
is_tolerate = false

rates = Array.new
basenames = Array.new


#################################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--prot', GetoptLong::NO_ARGUMENT],
  ['--nucl', GetoptLong::NO_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--indir'
      indir = File.expand_path(value)
    when '-t'
      treefile = File.expand_path(value)
    when '--outdir'
      outdir = File.expand_path(value)
    when '--prot'
      is_prot = true
    when '--nucl'
      is_nucl = true
      PROG = File.join(PAML_DIR, 'bin', 'baseml')
      CTL = File.join(DIR, 'baseml4CalculateSubRate.ctl')
    when '--cpu'
      cpu = value.to_i
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
  end
end


#################################################################
mkdir_with_force(outdir, is_force, is_tolerate)


#################################################################
`cp #{CTL} #{outdir}`
ctl_file = File.join(outdir, File.basename(CTL))


#################################################################
Dir.chdir(outdir)

Dir.foreach(indir) do |b|
  next if b =~ /^\./
  next if b !~ /(phylip|phy)$/
  basenames << b
end

all_taxa = get_taxa_from_full_species_tree(treefile).map{|node|node.name.gsub(' ', '_')}
# sometimes root_age "@10" might be removed during nw_prune so we add it back always
root_age = get_root_age(treefile)


results = Parallel.map(basenames, in_processes: cpu) do |b|
  ctl = b + '.ctl'
  `cp #{ctl_file} #{ctl}`
  outfile = b + '.out'
  seqfile = File.join(indir, b)
  treefile2 = b + '.tre'
  map_file = b + '.map'

  taxa = getTaxaFromPhylip(seqfile)
  # generate map_file and new seqfile
  `head -1 #{seqfile} >> #{b}; sed '1d' #{seqfile} | awk '{print NR"  "$2}' >> #{b}`
  `bash #{GET_MAP_FROM_PHYLIP} #{seqfile} > #{map_file}`

  # generate treefile2
  #taxa_excluded = all_taxa - taxa
  #`sed '1d' #{treefile} | nw_prune - #{taxa_excluded.join(" ")} | nw_rename - #{map_file} >> #{treefile2}`
  `sed '1d' #{treefile} | nw_prune - -v #{taxa.join(" ")} | nw_rename - #{map_file} > #{treefile2}`
  set_root_age_and_output_tree(treefile2, root_age, treefile2)
  `echo #{taxa.size} 1 | cat - #{treefile2} | sponge #{treefile2}`

  prepare_paml_ctl(ctl, outdir, {'seqfile'=>b, 'treefile'=>treefile2, 'outfile'=>outfile})
  `#{PROG} #{ctl}`
  rate = `cd #{outdir}; grep 'Substitution rate' -A1 #{outfile} | tail -1 | awk '{print $1}'`.chomp
  rate
end


results.each do |rate|
  rates << rate.to_f if rate =~ /\d/
end

Dir.chdir($PWD)


#################################################################
puts rates.join("\n")
puts
puts rates.sum/rates.size


