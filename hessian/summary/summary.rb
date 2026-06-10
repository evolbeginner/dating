#!/usr/bin/env ruby

require 'getoptlong'
require 'parallel'
require 'fileutils'

######################################################
DIR = File.dirname(__FILE__)
CALCULATE_BRANCH_SCORE = File.join(DIR, '../calculate_branch_score_dist.R')
OUTS = %w[score reldiff coefficient rs].freeze

######################################################
TypeInfo = Struct.new(:name, :ref_tree, :type_infile, :tf)

######################################################
def get_all_models(range)
  model_outdirs = Dir.glob(File.join(range.first, '**', 'LG+G'))
  return [] if model_outdirs.empty?
  subdir = File.dirname(model_outdirs[0])
  Dir.glob(File.join(subdir, '*/')).filter_map do |d|
    name = File.basename(d)
    name unless name == 'test'
  end
end

def get_all_cats(range)
  model_outdirs = Dir.glob(File.join(range.first, '**', 'root'))
  return [] if model_outdirs.empty?
  subdir = File.dirname(model_outdirs[0])
  Dir.glob(File.join(subdir, '*/')).map { |d| File.basename(d) }
end

def mkdir_with_force(path, force = false, tolerate = false)
  if File.exist?(path)
    if force
      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(path)
    elsif !tolerate
      raise "Directory #{path} already exists! Use --force or --tolerate."
    end
  else
    FileUtils.mkdir_p(path)
  end
end


def compute_branch_score(ref_tree_path, target_tree, tf)
  unless File.exist?(ref_tree_path)
    $stderr.puts "WARNING: ref tree not found: #{ref_tree_path}"
    return %w[NA NA NA NA]
  end
  unless File.exist?(target_tree)
    $stderr.puts "WARNING: target tree not found: #{target_tree}"
    return %w[NA NA NA NA]
  end

  cmd = "Rscript #{CALCULATE_BRANCH_SCORE} #{ref_tree_path} #{target_tree} 1 2 #{tf}"
  output = `#{cmd} 2>&1`.strip

  if $?.success? && !output.empty?
    fields = output.split("\t")
    if fields.size >= 4
      fields[0, 4]
    else
      $stderr.puts "WARNING: unexpected output (#{fields.size} fields) for #{target_tree}: #{output}"
      %w[NA NA NA NA]
    end
  else
    $stderr.puts "WARNING: Rscript failed (exit #{$?.exitstatus}) for #{target_tree}"
    $stderr.puts "  cmd: #{cmd}"
    $stderr.puts "  output: #{output}" unless output.empty?
    %w[NA NA NA NA]
  end
end


######################################################
# Defaults
cats = []
range = nil
dir = Dir.pwd
cpu = 4
models = %w[ori LG+G LG+C20+G LG+C40+G]
ages = %w[10 20 30 40]
age_name = 'age'
ref_type = 'sim'
ref_dir = 'sim/tree/'
branchwise = 'F'
outdir = nil
is_force = false
is_tolerate = false


######################################################
opts = GetoptLong.new(
  ['--cat',      GetoptLong::REQUIRED_ARGUMENT],
  ['--age',      GetoptLong::REQUIRED_ARGUMENT],
  ['--age_name', GetoptLong::REQUIRED_ARGUMENT],
  ['--mu',       GetoptLong::NO_ARGUMENT],
  ['-m', '--model', GetoptLong::REQUIRED_ARGUMENT],
  ['--range',    GetoptLong::REQUIRED_ARGUMENT],
  ['--ref_type', GetoptLong::REQUIRED_ARGUMENT],
  ['--branchwise', GetoptLong::NO_ARGUMENT],
  ['--cpu',      GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir',   GetoptLong::REQUIRED_ARGUMENT],
  ['--force',    GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
  when '--cat'         then cats = arg.split(',')
  when '--age'         then ages = arg.split(',')
  when '--mu'
    ages = %w[-1.6 -2.3 -3 -3.7]
    age_name = 'mu'
  when '--age_name'    then age_name = arg
  when '-m', '--model' then models = arg.split(',')
  when '--range'
    a = arg.split(/[-,:]/)
    range = (a[0]..a[-1])
  when '--ref_type'    then ref_type = arg
  when '--branchwise'  then branchwise = 'T'
  when '--cpu'         then cpu = arg.to_i
  when '--outdir'      then outdir = File.expand_path(arg)
  when '--force'       then is_force = true
  when '--tolerate'    then is_tolerate = true
  end
end

case age_name
when /rate|mu/ then ages = %w[-1.6 -2.3 -3 -3.7]
when 'age'     then ages = %w[10 20 30 40]
end

abort "outdir has to be specified!" if outdir.nil? || outdir.empty?
mkdir_with_force(outdir, is_force, is_tolerate)
abort "range has to be given by --range!" if range.nil?

######################################################
typesh = if ref_type == 'sim'
  {
    'time' => TypeInfo.new('time', 'time.tre', 'figtree.nwk', branchwise),
    'rate' => TypeInfo.new('rate', 'rate.tre', 'rate.tre',     'T')
  }
else
  ref_dir = "dating/#{ref_type}/combined"
  {
    'time' => TypeInfo.new('time', 'figtree.nwk', 'figtree.nwk', branchwise),
    'rate' => TypeInfo.new('rate', 'rate.tre',     'rate.tre',     'T')
  }
end

######################################################
models    = get_all_models(range) if models == ['all']
cats      = get_all_cats(range)   if cats == ['all']
range_arr = range.to_a

# Create output directories upfront
cats.each { |cat| mkdir_with_force(File.join(outdir, cat), false, true) }

######################################################
# Build flat task list: every (k, age, cat, type, model) combination
# This enables full parallelism across ALL dimensions, not just k.
tasks = []
range_arr.each do |k|
  ages.each do |age|
    cats.each do |cat|
      typesh.each_pair do |type, type_obj|
        models.each_with_index do |model, model_idx|
          tasks << {
            k: k, age: age, cat: cat, type: type,
            type_infile: type_obj.type_infile,
            ref_tree: type_obj.ref_tree, tf: type_obj.tf,
            model: model, model_idx: model_idx
          }
        end
      end
    end
  end
end

$stderr.puts "Running #{tasks.size} tasks across #{cpu} processes..."

# Execute ALL R script calls in parallel (worker processes are reused)
results = Parallel.map(tasks, in_processes: cpu) do |task|
  subdir     = File.join(dir, task[:k].to_s)
  target_dir = File.join(subdir, "#{age_name}-#{task[:age]}", task[:cat])
  target_tree   = File.join(target_dir, 'dating', task[:model], 'combined', task[:type_infile])
  ref_tree_path = File.join(target_dir, ref_dir, task[:ref_tree])

  values = compute_branch_score(ref_tree_path, target_tree, task[:tf])

  { k: task[:k], age: task[:age], cat: task[:cat], type: task[:type],
    model_idx: task[:model_idx], values: values }
end

######################################################
# Organize: grouped[(cat, type, age, k)] => array of [score, reldiff, coeff, rs] per model
grouped = {}
results.each do |r|
  key = [r[:cat], r[:type], r[:age], r[:k]]
  grouped[key] ||= Array.new(models.size)
  grouped[key][r[:model_idx]] = r[:values]
end

######################################################
# Write all output files in one pass — no temp files, no cut, no transpose.rb
cats.each do |cat|
  sub_outdir = File.join(outdir, cat)

  typesh.each_pair do |type, type_obj|
    ages.each do |age|
      OUTS.each_with_index do |out, col_idx|
        outfile = File.join(sub_outdir, "#{type_obj.name}.#{age}.#{out}")
        File.open(outfile, 'w') do |fh|
          fh.puts models.join("\t")
          range_arr.each do |k|
            row = grouped[[cat, type, age, k]]
            if row
              fh.puts row.map { |v| v ? v[col_idx] : 'NA' }.join("\t")
            else
              fh.puts (['NA'] * models.size).join("\t")
            end
          end
        end
      end
    end
  end
end

$stderr.puts "Done. Results written to #{outdir}"

