#! /usr/bin/env ruby


#####################################################################
require 'getoptlong'

require 'SSW_bio'
require 'Dir'


#####################################################################
indir1 = nil
indir2 = nil
outdir = nil
is_force = false

gene2seqObjs = Array.new


#####################################################################
def getGene2SeqObjs(indir)
  gene2seqObjs = Hash.new
  infiles = read_infiles(indir)
  infiles.each do |infile|
    b = File.basename(infile)
    gene2seqObjs[b] = read_seq_file(infile)
  end
  return(gene2seqObjs)
end


#####################################################################
opts = GetoptLong.new(
  ['--indir1', GetoptLong::REQUIRED_ARGUMENT],
  ['--indir2', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--indir1'
      indir1 = value
    when '--indir2'
      indir2 = value
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
  end
end


#####################################################################
mkdir_with_force(outdir, is_force)

gene2seqObjs << getGene2SeqObjs(indir1)

gene2seqObjs << getGene2SeqObjs(indir2)


#####################################################################
gene2seqObjs[0].each do |b, seqObjs|
  if ! gene2seqObjs[1].include? b
    puts b; next
  end

  outfile = File.join(outdir, b)
  out_fh = File.open(outfile, 'w')
  seqObjs.each do |title, seqObj|
    if gene2seqObjs[1][b].include?(title)
      out_fh.puts '>'+title
      out_fh.puts gene2seqObjs[1][b][title].seq
    end
  end
  out_fh.close
end



