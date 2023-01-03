#! /usr/bin/env ruby


###############################################
require 'getoptlong'

require 'Dir'
require 'util'


###############################################
TAXON2N = {
  :Rhizobiales => 221,
  :rhizobial_lineages => 224,
  :Brady => 267,
  :Meso => 296,
  :Sino => 353,
  :Rhizo => 345,
  :Bartonella => 318,
  :Brucella => 312,
  :Methylobacterium => 235,
  :SAR => 324,
}


###############################################
infiles = Array.new
outdir = nil
outdir2 = nil
is_force = false


###############################################
def get_first_n(infile)
  first_n = nil
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    first_node = line.split("\t")[1]
    first_node =~ /t_n(\d+)/
    first_n = $1.to_i
    break
  end
  in_fh.close
  return(first_n)
end


###############################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--normal', GetoptLong::REQUIRED_ARGUMENT],
  ['--prior', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir2', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infiles << value
    when '--normal'
      infiles << value
    when '--prior'
      infiles << value
    when '--outdir'
      outdir = value
    when '--outdir2'
      outdir2 = value
    when '--force'
      is_force = true
  end
end


###############################################
mkdir_with_force(outdir, is_force)
mkdir_with_force(outdir2, is_force)


###############################################
first_n = get_first_n(infiles[0])


TAXON2N.each_pair do |taxon, n|
  outfiles = Array.new
  infiles.each do |infile|
    c = getCorename(infile)
    type = c.split('-')[0]
    outfile = File.join(outdir, taxon.to_s + '-' + type + '.mcmc')
    outfiles << outfile
    f = n - first_n + 2
    puts "sed '1d' #{infile} | cut -f #{f} > #{outfile}"
    `sed '1d' #{infile} | cut -f #{f} > #{outfile}`
  end
  outfile2 = File.join(outdir2, taxon.to_s+'.mcmc')
  puts "column_combine.rb -i #{outfiles[0]} -i #{outfiles[1]} > #{outfile2}"
  `column_combine.rb -i #{outfiles[1]} -i #{outfiles[0]} > #{outfile2}`
  `awk 'BEGIN{OFS="\t"}{for(i=1;i<=NF;i++){if($i~/[0-9]/){$i=$i*100}} print}' #{outfile2} | sponge #{outfile2}`
end


