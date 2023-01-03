#! /usr/bin/env ruby


###############################################################
# Author: Sishuo Wang from Haiwei Luo Lab at Chinese University of Hong Kong
# E-mail: sishuowang@hotmail.ca sishuowang@cuhk.edu.hk
# Last updated: 2019-11-30
# Copyright: CC 4.0 (https://creativecommons.org/licenses/by/4.0/)
# To see the usage, run the script with '-h'

# v1.1 2019-11-30 (inspired by Tianhua Liao from CUHK):
#   1. allowing running MCMCTree in parallel with "--cpu n"
#   2. disabling codeml/baseml in the first run of mcmctree


#################################################################
require 'getoptlong'
require 'parallel'
require 'time'

require 'Dir'


#################################################################
$PWD = Dir.getwd

PAML_DIR = File.expand_path("~/software/phylo/paml/")
MCMCTREE_CTL = File.join(PAML_DIR, 'mcmctree.ctl')
CODEML_CTL = File.join(PAML_DIR, 'codeml.ctl')
MCMCTREE = File.join(PAML_DIR, 'src', 'mcmctree')


#################################################################
seqfile = nil
treefile = nil
seqtype = nil
outdir = nil
clock = 2
bd_paras = '1 1 0.1'
rgene_gamma = '1 50 1'
sigma2_gamma = '1 10 1'
alpha = 0.5
ncatG = 5
burnin = '2000'
sampfreq = '2'
nsample = '20000'
sub_model = 'lg'
other_args = Hash.new
cpu = 1
is_force = false
is_tolerate = false

times = Array.new


#################################################################
def pf(arr)
  printf("%-50s%-80s\n", arr[0], arr[1])
end


def usage()
  STDERR.puts
  pf ['-i', "infile (in phylip format)"]
  pf ['-t', 'treefile']
  pf ['--outdir', 'outdir']
  pf ['--nucl', 'to do analysis for DNA alignments']
  pf ['--pep|prot', 'to do analysis for protein alignents']
  pf ['--clock', "the clock"]
  pf ['--BDparas|BD', "the value for BDparas (default: 1 1 0.1)"]
  pf ['--rgene|rgene_gamma', "the value for rgene_gamma (default: 1 50 1)"]
  pf ['--sigma|sigma2|sigma_gamma|sigma2_gamma', "the value for sigma2_gamma"]
  pf ['--bsn', "the value for bsn (burnin, sampfreq, nsample; default: 2000,2,20000)"]
  pf ['--alpha', "alpha in Gamma Dist"]
  pf ['--ncatG', "the no. of Gamma categories; default: 4"]
  pf ['--nsample', "the no. of samples"]
  pf ['--sub_model', "substitution model (default: LG for protein)"]
  pf ['--cpu', "cpu no."]
  pf ['--force', "remove the outdir if it exists"]
  pf ['--tolerate', "keep the outdir if it exists"]
  STDERR.puts "Please contact Sishuo Wang (sishuowang@hotmail.ca) if there are any questions. Thanks."
  exit 1
end



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


def prepare_paml_ctl(ctl_file, outdir, h, other_args)
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

  (h.keys - dones.keys).each do |i|
    lines << sprintf_argu_line(i, h[i], 14)
  end

  other_args.each_key do |i|
    lines << sprintf_argu_line(i, other_args[i], 14)
  end

  out_fh = File.open(ctl_file, 'w')
  out_fh.puts lines.join("\n")
  out_fh.close
end


#################################################################
usage() if ARGV.empty?


opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--nucl', GetoptLong::NO_ARGUMENT],
  ['--pep', '--prot', GetoptLong::NO_ARGUMENT],
  ['--clock', GetoptLong::REQUIRED_ARGUMENT],
  ['--BDparas', '--BD', GetoptLong::REQUIRED_ARGUMENT],
  ['--rgene', '--rgene_gamma', GetoptLong::REQUIRED_ARGUMENT],
  ['--sigma', '--sigma2', '--sigma_gamma', '--sigma2_gamma', GetoptLong::REQUIRED_ARGUMENT],
  ['--bsn', GetoptLong::REQUIRED_ARGUMENT],
  ['--alpha', GetoptLong::REQUIRED_ARGUMENT],
  ['--ncatG', GetoptLong::REQUIRED_ARGUMENT],
  ['--nsample', GetoptLong::REQUIRED_ARGUMENT],
  ['--sub_model', GetoptLong::REQUIRED_ARGUMENT],
  ['--bf', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
  ['--regular', GetoptLong::NO_ARGUMENT],
  ['--fastest', GetoptLong::NO_ARGUMENT],
  ['-h', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      seqfile = File.expand_path(value)
    when '-t'
      treefile = File.expand_path(value)
    when '--outdir'
      outdir = File.expand_path(value)
    when '--nucl'
      seqtype = 0
    when '--prot', '--pep'
      seqtype = 2
    when '--clock'
      clock = value
    when '--BDparas', '--BD'
      bd_paras = value.gsub(",", ' ')
    when '--rgene', '--rgene_gamma'
      rgene_gamma = value.gsub(",", ' ')
    when '--sigma', '--sigma2', '--sigma_gamma', '--sigma2_gamma'
      sigma2_gamma = value
    when '--bsn'
      arr = value.split(',')
      raise "bsn has to be x,y,z" if arr.size != 3
      burnin, sampfreq, nsample = arr
    when '--alpha'
      alpha = value.to_f
    when '--ncatG'
      ncatG = value.to_i
    when '--nsample'
      nsample = value
    when '--sub_model'
      sub_model = value.downcase
    when '--bf'
      other_args['BayesFactorBeta'] = value.to_f
    when '--cpu'
      cpu = value.to_i
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
    when '--regular'
      ;
    when '--fastest'
      clock = 1; alpha = 0.01; ncatG = 2; burnin, sampfreq, nsample = 1000, 2, 10000
    when '-h'
      usage()
  end
end


#################################################################
AA_RATE_FILE = File.join(PAML_DIR, 'dat', sub_model + '.dat')


#################################################################
if seqtype.nil?
  STDERR.puts "seqtype has to be given! Exiting ......"
  exit 1
end

mkdir_with_force(outdir, is_force, is_tolerate)

ndata = get_ndata(seqfile)


#################################################################
`cp #{MCMCTREE_CTL} #{outdir}`
ctl_file = File.join(outdir, File.basename(MCMCTREE_CTL))

times << Time.now
puts 'mcmctree'

seqfile_b = File.basename(seqfile)
`cp #{seqfile} #{outdir}/#{seqfile_b}`
treefile_b = File.basename(treefile)
`cp #{treefile} #{outdir}/#{treefile_b}`

#prepare_paml_ctl(ctl_file, outdir, {'seqfile'=>seqfile_b, 'treefile'=>treefile_b, 'ndata'=>ndata, 'seqtype'=>seqtype, 'usedata'=>3, 'clock'=>clock, 'BDparas'=>bd_paras, 'rgene_gamma'=>rgene_gamma, 'sigma2_gamma'=>sigma2_gamma})
prepare_paml_ctl(ctl_file, outdir, {'seqfile'=>seqfile_b, 'treefile'=>treefile_b, 'ndata'=>ndata, 'seqtype'=>seqtype, 'usedata'=>3, 'clock'=>clock, 'BDparas'=>bd_paras, 'rgene_gamma'=>rgene_gamma, 'sigma2_gamma'=>sigma2_gamma, 'burnin'=>burnin, 'sampfreq'=>sampfreq, 'nsample'=>nsample, 'alpha'=>alpha, 'ncatG'=>ncatG}, {})

Dir.chdir(outdir)
`echo $$ > #{outdir}/mcmctree.first`
# Disable codeml
`mkdir disabled_bin; cd disabled_bin; touch {codeml,baseml}; chmod +x {codeml,baseml}; export PATH=$PWD:$PATH; cd ../; which codeml >> #{outdir}/mcmctree.first; #{MCMCTREE} mcmctree.ctl >> #{outdir}/mcmctree.first`

STDERR.puts "ctl_file name #{ctl_file} is too long. Exiting ......" or exit 1 if ctl_file.size >= 128

`mv out.BV in.BV`
Dir.chdir($PWD)


#################################################################
times << Time.now; puts "Running time: " + (times[-1]-times[-2]).to_s + " seconds"
puts 'codeml'

if seqtype == 2
  Dir.chdir(outdir)
  `rm in.BV` if File.exists?('in.BV')

  Parallel.map(1..ndata, in_processes: cpu) do |i|
    Dir.chdir(outdir)
    c = 'tmp'+(sprintf "%04d",i)
    b = 'tmp'+(sprintf "%04d",i)+'.ctl'
    sub_outdir = File.join(outdir, c)
    `mkdir #{c}; mv #{c}.* #{c}`
    prepare_paml_ctl(File.join(sub_outdir,b), '', {'model'=>2,'aaRatefile'=>AA_RATE_FILE,'fix_alpha'=>0,'alpha'=>alpha, 'ncatG'=>ncatG}, {})

    Dir.chdir(sub_outdir)
    `codeml #{b}`
  end

  Dir.chdir(outdir)
  1.upto(ndata).each do |i|
    c = 'tmp'+(sprintf "%04d",i)
    `cat #{outdir}/#{c}/rst2 >> in.BV`
  end
  Dir.chdir($PWD)

end


#################################################################
times << Time.now; puts "Running time: " + (times[-1]-times[-2]).to_s + " seconds"
puts 'mcmctree'

prepare_paml_ctl(ctl_file, outdir, {'seqfile'=>seqfile_b, 'treefile'=>treefile_b, 'ndata'=>ndata, 'seqtype'=>seqtype, 'usedata'=>"2 in.BV 1", 'clock'=>clock, 'BDparas'=>bd_paras, 'rgene_gamma'=>rgene_gamma, 'sigma2_gamma'=>sigma2_gamma, 'burnin'=>burnin, 'sampfreq'=>sampfreq, 'nsample'=>nsample, 'alpha'=>alpha, 'ncatG'=>ncatG}, other_args)
Dir.chdir(outdir)
`echo $$ > #{outdir}/mcmctree.final; #{MCMCTREE} mcmctree.ctl >> #{outdir}/mcmctree.final`
Dir.chdir($PWD)


#################################################################
if $?.to_i == 0
  puts "DONE!"
else
  puts "There was a problem. Please check it."
end


#################################################################
times << Time.now; puts "Running time: " + (times[-1]-times[-2]).to_s + " seconds"


