#! /bin/env ruby


require 'getoptlong'
require 'parallel'
require 'fileutils'
require 'Dir'


######################################################
DIR = File.dirname($0)


######################################################
CALCULATE_BRANCH_SCORE = File.join(DIR, '../', 'calculate_branch_score_dist.R')

OUTS = %w[score reldiff coefficient rs]


######################################################
class TYPE
  attr_accessor :name, :ref_tree, :type_infile, :tf
  def initialize(name, ref_tree, type_infile, tf)
    @name = name
    @ref_tree = ref_tree
    @type_infile = type_infile
    @tf = tf
  end
end


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


def write_header(models, cat, age, type_obj, outdir)
  OUTS.each do |out|
    #outfile = File.join(outdir, "#{cat}-#{age}.#{out}")
    sub_outdir = File.join(outdir, cat)
    mkdir_with_force(sub_outdir, false, true)
    outfile = File.join(sub_outdir, "#{type_obj.name}.#{age}.#{out}")
    existing_contents = File.read(outfile)
    out_fh = File.open(outfile, 'w')
    out_fh.puts models.join("\t")
    out_fh.write existing_contents
    out_fh.close
  end
end


def process_k(cats, models, age_name, ages, typesh, k, outdir, dir, ref_dir)
  subdir = File.join(dir, k.to_s)

  ages.each do |age|
    tmp_out = File.join(outdir, "tmp.out-#{k}-#{age}")
    FileUtils.rm(tmp_out) if File.exist?(tmp_out)
    cats.each do |cat|
      mkdir_with_force(File.join(outdir,cat), false, true)
      target_dir = File.join(subdir, "#{age_name}-#{age}", cat)
      typesh.each_pair do |type, type_obj|
        models.each do |m|
          target_tree = File.join(target_dir, "dating/#{m}/combined/", type_obj.type_infile)
          cmd = "Rscript #{CALCULATE_BRANCH_SCORE} #{File.join(target_dir, ref_dir+'/'+ type_obj.ref_tree)} #{target_tree} 1 2 #{type_obj.tf} >> #{tmp_out}"
          ` #{cmd} `
          if $? != 0
            puts target_tree
            `printf "NA\tNA\tNA\tNA\t\n" >> #{tmp_out}`
          end
        end
        prefix = [type, age].join('.')
        system("cut -f1 #{tmp_out} | transpose.rb -i - >> #{File.join(outdir, "#{cat}/#{prefix}.score")}")
        system("cut -f2 #{tmp_out} | transpose.rb -i - >> #{File.join(outdir, "#{cat}/#{prefix}.reldiff")}")
        system("cut -f3 #{tmp_out} | transpose.rb -i - >> #{File.join(outdir, "#{cat}/#{prefix}.coefficient")}")
        system("cut -f4 #{tmp_out} | transpose.rb -i - >> #{File.join(outdir, "#{cat}/#{prefix}.rs")}")
        FileUtils.rm(tmp_out)
      end
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
age_name = 'age'
is_mu = false

ref_type = 'sim'
ref_dir = 'sim/tree/'

outdir = nil
is_force = false
is_tolerate = false


######################################################
# Parse arguments
opts = GetoptLong.new(
  ['--cat', GetoptLong::REQUIRED_ARGUMENT],
  ['--age', GetoptLong::REQUIRED_ARGUMENT],
  ['--age_name', GetoptLong::REQUIRED_ARGUMENT],
  ['--mu', GetoptLong::NO_ARGUMENT],
  ['-m', '--model', GetoptLong::REQUIRED_ARGUMENT],
  ['--range', GetoptLong::REQUIRED_ARGUMENT],
  ['--ref_type', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
    when '--cat'
      cats = arg.split(',')
    when '--age'
      ages = value.split(',')
    when '--mu'
      is_mu = true
      ages = %w[-1.6 -2.3 -3 -3.7]
      age_name = 'mu'
    when '--age_name'
      age_name = arg
    when '-m', '--model'
      models = arg.split(',')
    when '--range'
      a = arg.split(/[-,:]/)
      range = (a[0]..a[-1])
    when '--ref_type'
      ref_type = arg
    when '--cpu'
      cpu = arg.to_i
    when '--outdir'
      outdir = File.expand_path(arg)
    when '--force'
      is_force = true
    when '--tolerate'
      is_tolerate = true
  end
end

case age_name
  when /rate|mu/
     ages = %w[-1.6 -2.3 -3 -3.7]
  when 'age'
    ages = [10, 20, 30, 40].map(&:to_s)
end


if outdir.nil? || outdir.empty?
  puts "outdir has to be specified!"
  exit 1
end


mkdir_with_force(outdir, is_force, is_tolerate)
raise "range has to be given by --range! Exiting ......" if range.nil?


######################################################
if ref_type == 'sim'
  typesh = {
    'time' => TYPE.new('time', 'time.tre', 'figtree.nwk', 'F'), 
    'rate' => TYPE.new('rate', 'rate.tre', 'rate.tre', 'T')
  }
else
  typesh = {
    'time' => TYPE.new('time', 'figtree.nwk', 'figtree.nwk', 'F'), 
    'rate' => TYPE.new('rate', 'rate.tre', 'rate.tre', 'T')
  }
  ref_dir = ['dating', ref_type, 'combined'].join('/')
end


######################################################
models = get_all_models(range) if models == ['all']
cats = get_all_cats(range) if cats == ['all']

Parallel.each(range, in_processes: cpu) do |k|
  process_k(cats, models, age_name, ages, typesh, k, outdir, dir, ref_dir)
end

cats.each do |cat|
  ages.each do |age|
    typesh.each_pair do |type, type_obj|
      write_header(models, cat, age, type_obj, outdir)
    end
  end
end


