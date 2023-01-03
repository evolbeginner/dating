#! /usr/bin/env ruby


###################################################################
dir = File.dirname($0)
lib_path = File.join(dir, 'lib')
$: << lib_path


###################################################################
require 'getoptlong'
require 'parallel'

require 'Dir'
require 'chang_yong'
require 'seqIO'
require 'util'


###################################################################
seq_indirs = Array.new
infile = nil
seq_suffix = 'rrna'
types = Array.new
cpu = 1
out2in_files = Array.new
outdir = nil
is_force = false
is_tolerate = false

species_included = Hash.new
seq_files = Array.new
reg_exps = Hash.new
rRNA_seq_objs = Hash.new{|h1,k1|h1[k1]=Hash.new{|h2,k2|h2[k2]=[]}}

$in2out = Hash.new
$out2in = Hash.new


###################################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--out2in', '--out2in_file', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--indir'
      seq_indirs << value.split(',')
    when '-i'
      infile = value
    when '--cpu'
      cpu = value.to_i
    when '-t'
      types << value.split(',')
    when /^--(out2in|out2in_file)$/
      value.split(',').map{|i|out2in_files << File.expand_path(i)}
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
  end
end


###################################################################
seq_indirs.flatten!
types.flatten!

types.each do |type|
  reg_exps[type] = ['\['+type, 'ribosomal RNA\]'].join(' ')
end

mkdir_with_force(outdir, is_force, is_tolerate)

species_included = read_list(infile)
out2in_files.flatten!

if not out2in_files.empty?
  $out2in, $in2out = getSpeciesNameRela(out2in_files)
else
  $out2in, $in2out = getSpeciesNameRelaWithoutFile(species_included)
end


###################################################################
seq_indirs.each do |seq_indir|
  seq_files << read_infiles(seq_indir, seq_suffix)
end
seq_files.flatten!

seq_objs = read_seq_from_dir(seq_files, seq_suffix, species_included, cpu, $in2out)


seq_objs.each_pair do |taxon, fs|
  fs.each_pair do |seq_title, f|
    reg_exps.each_pair do |type, reg_exp|
      if f.definition =~ /#{reg_exp}/
        #p [taxon, seq_title, f.definition]
        rRNA_seq_objs[type][taxon] << f
      end
    end
  end
end


###################################################################
rRNA_seq_objs.each_pair do |type, v1|
  outfile = File.join(outdir, type+'.fas')
  out_fh = File.open(outfile, 'w')
  v1.each_pair do |taxon, fs|
    out_fh.puts '>' + taxon
    out_fh.puts fs.sort_by{|f|f.seq.size}[-1].seq
  end
  out_fh.close
end


