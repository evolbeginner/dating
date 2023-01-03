#! /usr/bin/env ruby


#####################################################################################
require 'getoptlong'
require 'parallel'
require 'bio'

require 'Dir'


#####################################################################################
MFA2PHY = 'MFAtoPHY.pl'


#####################################################################################
indir = nil
infiles = Array.new
outdir = nil
codon_12_outdir = nil
min = 1
cpu = 1
is_force = false
is_tolerate = false
is_optimize = false

seqNums = Hash.new


#####################################################################################
def getSeqNums(outfiles)
  counts = Hash.new
  outfiles.each do |outfile|
    count = 0
    in_fh = File.open(outfile, 'r')
    in_fh.each_line do |line|
      line.chomp!
      count += 1 if line =~ /^>/
    end
    in_fh.close
    counts[outfile] = count
  end
  return(counts)
end


def create_codon_12_alns(infiles, codon_12_outdir, cpu, is_force, is_tolerate)
  mkdir_with_force(codon_12_outdir, is_force, is_tolerate)
  outfiles = Array.new

  infiles.each do |infile|
    in_fh = Bio::FlatFile.open(infile)
    b = File.basename(infile)
    outfile = File.expand_path(File.join(codon_12_outdir, b))
    outfiles << outfile
    out_fh = File.open(outfile, 'w')
    
    in_fh.each_entry do |f|
      f.seq.gsub!(/(.)(.)./, "\\1\\2")
      out_fh.puts '>' + f.definition
      out_fh.puts f.seq
    end
    in_fh.close
    out_fh.close
  end

  return(outfiles)
end


#####################################################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--codon_12_outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--min', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
  ['--optimize', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infiles << value.split(',')
    when '--indir'
      indir = File.expand_path(value)
    when '--outdir'
      outdir = value
    when '--codon_12_outdir'
      codon_12_outdir = value
    when '--min'
      min = value.to_i
    when '--cpu'
      cpu = value.to_i
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
    when '--optimize'
      is_optimize = true
  end
end


#####################################################################################
mkdir_with_force(outdir, is_force, is_tolerate)

if not indir.nil?
  infiles << read_infiles(indir)
end
infiles.flatten!

if not codon_12_outdir.nil?
  infiles = create_codon_12_alns(infiles, codon_12_outdir, cpu, is_force, is_tolerate)
end

infiles.each do |infile|
  `ln -s #{infile} #{outdir}`
end

outfiles = read_infiles(outdir)

seqNums = getSeqNums(outfiles)

Parallel.map(outfiles, in_processes:cpu) do |outfile|
#outfiles.each do |outfile|
  next if seqNums[outfile] < seqNums.values.max if is_optimize
  `rm #{outfile}` and next if seqNums[outfile] < min
  `#{MFA2PHY} #{outfile}`
  `rm #{outfile}`
end


