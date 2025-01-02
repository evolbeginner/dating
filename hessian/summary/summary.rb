#! /bin/env ruby

require 'getoptlong'
require 'parallel'
require 'fileutils'
require 'Dir'


######################################################
DIR = File.dirname($0)


######################################################
CALCULATE_BRANCH_SCORE = File.join(DIR, '../hessian', 'calculate_branch_score_dist.R')

TYPES = %w[score reldiff coefficient rs]


######################################################
def get_all_models(range)
  bs = []
  model_outdirs = Dir.glob(File.join(range.to_a[0], '**', 'LG+G'))
  subdir = File.dirname(model_outdirs[0])
  Dir.glob(File.join(subdir, '*/')).each do |d|
    next if File.basename(d) == 'test'
    bs << File.basename(d)
  end
  return(bs)
end


def get_all_cats(range)
  bs = []
  model_outdirs = Dir.glob(File.join(range.to_a[0], '**', 'root'))
  subdir = File.dirname(model_outdirs[0])
  Dir.glob(File.join(subdir, '*/')).each do |d|
    bs << File.basename(d)
  end
  return(bs)
end


def write_header(models, cat, age, outdir)
  TYPES.each do |type|
    #outfile = File.join(outdir, "#{cat}-#{age}.#{type}")
    sub_outdir = File.join(outdir, cat)
    mkdir_with_force(sub_outdir, false, true)
    outfile = File.join(sub_outdir, "#{age}.#{type}")
    existing_contents = File.read(outfile)
    out_fh = File.open(outfile, 'w')
    out_fh.puts models.join("\t")
    out_fh.write existing_contents
    out_fh.close
  end
end


def process_k(cats, models, ages, k, outdir, dir)
  puts k
  subdir = File.join(dir, k.to_s)

  ages.each do |age|
    tmp_out = File.join(outdir, "tmp.out-#{k}-#{age}")
    FileUtils.rm(tmp_out) if File.exist?(tmp_out)
    cats.each do |cat|
      mkdir_with_force(File.join(outdir,cat), false, true)
      target_dir = File.join(subdir, "age-#{age}", cat)
      models.each do |m|
        target_tree = File.join(target_dir, "dating/#{m}/combined/figtree.nwk")
        cmd = "Rscript #{CALCULATE_BRANCH_SCORE} #{File.join(target_dir, 'sim/tree/time.tre')} #{target_tree} 1 2 F >> #{tmp_out}"
        ` #{cmd} `
        if $? != 0
          puts target_tree
          `echo -e "NA\tNA\tNA\tNA" >> #{tmp_out}`
        end
      end
      system("cut -f1 #{tmp_out} | transpose.rb -i - >> #{File.join(outdir, "#{cat}/#{age}.score")}")
      system("cut -f2 #{tmp_out} | transpose.rb -i - >> #{File.join(outdir, "#{cat}/#{age}.reldiff")}")
      system("cut -f3 #{tmp_out} | transpose.rb -i - >> #{File.join(outdir, "#{cat}/#{age}.coefficient")}")
      system("cut -f4 #{tmp_out} | transpose.rb -i - >> #{File.join(outdir, "#{cat}/#{age}.rs")}")
      FileUtils.rm(tmp_out)
    end
  end
end


######################################################
# Default values
cats = Array.new
range = nil
dir = Dir.pwd
cpu = 4
models = ['ori', 'LG+G', 'LG+C20+G', 'LG+C40+G']
ages = [10, 20, 30, 40].map(&:to_s)
is_mu = false

outdir = nil
is_force = false


######################################################
# Parse arguments
opts = GetoptLong.new(
  ['--cat', GetoptLong::REQUIRED_ARGUMENT],
  ['--age', GetoptLong::REQUIRED_ARGUMENT],
  ['--mu', GetoptLong::REQUIRED_ARGUMENT],
  ['-m', '--model', GetoptLong::REQUIRED_ARGUMENT],
  ['--range', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
    when '--cat'
      cats = arg.split(',')
    when '--age'
      ages = value.split(',')
    when '--mu'
      ages = value.split(',')
      is_mu = true
    when '-m', '--model'
      models = arg.split(',')
    when '--range'
      a = arg.split(/[-,:]/)
      range = (a[0]..a[-1])
    when '--cpu'
      cpu = arg.to_i
    when '--outdir'
      outdir = File.expand_path(arg)
    when '--force'
      is_force = true
  end
end

if outdir.nil? || outdir.empty?
  puts "outdir has to be specified!"
  exit 1
end


mkdir_with_force(outdir, is_force)
raise "range has to be given by --range! Exiting ......" if range.nil?


######################################################
models = get_all_models(range) if models == ['all']
cats = get_all_cats(range) if cats == ['all']


Parallel.each(range, in_processes: cpu) do |k|
  process_k(cats, models, ages, k, outdir, dir)
end

cats.each do |cat|
  ages.each do |age|
    write_header(models, cat, age, outdir)
  end
end


