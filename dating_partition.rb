#! /usr/bin/env ruby


####################################################
require 'getoptlong'
require 'tempfile'

require 'Dir'


####################################################
$CREATE_CFG=File.expand_path("~/LHW-tools/SEQ2TREE/create_cfg.rb")

tbl_file = nil
indir = nil
outdir = nil
is_force = false
is_tolerate = false

corenames = Array.new
corename2seq = Hash.new


####################################################
opts = GetoptLong.new(
  ['--tbl', GetoptLong::REQUIRED_ARGUMENT],
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--tbl'
      tbl_file = value
    when '--indir'
      indir = value
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
  end
end


####################################################
mkdir_with_force(outdir, is_force, is_tolerate)

infiles = read_infiles(indir)


####################################################
in_fh = File.open(tbl_file, 'r')
in_fh.each_line do |line|
  line.chomp!
  line_arr = line.split("\t")
  corenames << line_arr
end
in_fh.close


infiles.each do |infile|
  b = File.basename(infile)
  corename = corenames.flatten.select{|i| b =~ /#{i}/}.shift
  if corename.nil?
    puts "aln_file #{b} not found in tbl #{tbl_file}"
  end
  corename2seq[corename] = infile
end


####################################################
corenames.each_with_index do |a, index|
  aln_outfile = File.join(outdir, index.to_s+'.fas')
  phy_outfile = aln_outfile + '.phy'
  str_arr = a.map{|i|corename2seq[i]}.compact
  next if str_arr.empty?
  str = str_arr.join(',')
  `ruby #{$CREATE_CFG} -i #{str} --mfa2phy --aln #{aln_outfile}`
  `rm #{aln_outfile}`
  `cat #{outdir}/* > #{outdir}/../combined.phy`
end


