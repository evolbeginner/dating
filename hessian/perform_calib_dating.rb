#!/usr/bin/env ruby

require 'getoptlong'
require 'fileutils'
require 'parallel'

require 'Dir'


##############################################
# Constants
DIR = File.dirname($0)
#MAKE_CALIB_TO_TREE = File.expand_path('~/project/Rhizobiales/scripts/dating/hessian/make_calib_to_tree.R')
MAKE_CALIB_TO_TREE = File.join(DIR, 'make_calib_to_tree.R')
RUN_MCMCTREE_IN_BATCH = File.expand_path("~/lab-tools/dating/run_mcmctree_in_batch.sh")


##############################################
# Helper function to create directories with optional force
def mkdir_with_force(outdir, is_force)
  if Dir.exist?(outdir) && !is_force
    puts "Directory #{outdir} already exists! Use --force to overwrite."
    exit 1
  end
  FileUtils.mkdir_p(outdir)
end


##############################################
# Variables
indir = ''
only_min_arg = ''
only_max_arg = ''
is_run_mcmctree = false
cpu = 1
outdir = ''
is_force = false
num = 2
percent = 0.2
shift_percent = 0.0


# Option parsing using GetoptLong
opts = GetoptLong.new(
  ["--indir", GetoptLong::REQUIRED_ARGUMENT],
  ["--num", GetoptLong::REQUIRED_ARGUMENT],
  ["-p", "--percent", GetoptLong::REQUIRED_ARGUMENT],
  ['-s', '--sp', '--shift', '--shift_percent', GetoptLong::REQUIRED_ARGUMENT],
  ["--only_min", GetoptLong::NO_ARGUMENT],
  ["--only_max", GetoptLong::NO_ARGUMENT],
  ["--run_mcmctree", GetoptLong::NO_ARGUMENT],
  ["--cpu", GetoptLong::REQUIRED_ARGUMENT],
  ["--outdir", GetoptLong::REQUIRED_ARGUMENT],
  ["--force", GetoptLong::NO_ARGUMENT],
  ['-h', "--help", GetoptLong::NO_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
    when '--indir'
      indir = arg
    when '--num'
      num = arg.to_i
    when '-p', '--percent'
      percent = arg.to_f
    when '-s', '--sp', '--shift', '--shift_percent'
      shift_percent = arg.to_f
    when '--only_min'
      only_min_arg = '--only_min'
    when '--only_max'
      only_max_arg = '--only_max'
    when '--run_mcmctree'
      is_run_mcmctree = true
    when '--cpu'
      cpu = arg.to_i
    when '--outdir'
      outdir = arg
    when '--force'
      is_force = true
    when '-h', '--help'
      puts "Usage: script.rb [options]"
      puts "--indir DIR         Input directory"
      puts "--outdir DIR        Output directory"
      puts "--num NUM           Number of trees"
      puts "--only_min          Only minimum (but for root still <> as a max is required for mcmctree)"
      puts "--only_max          Only max"
      puts "--run_mcmctree     Run MCMCTree"
      puts "--force             Force overwrite"
      exit 0
  end
end


##############################################
# Create output directory
mkdir_with_force(outdir, is_force)

# Copy directories
FileUtils.cp_r("#{indir}/sim", outdir)
FileUtils.cp_r("#{indir}/dating", outdir)
FileUtils.cp_r("#{indir}/ref.tre", outdir) if File.exist?(File.join(indir, 'ref.tre'))

# Get the real path of the current directory
dir = Dir.pwd

# Process time tree
timetree = "#{indir}/sim/tree/time.tre"
tipN = `nw_stats #{timetree} | grep leaves | awk '{print $2}'`.strip
cmd = "Rscript #{MAKE_CALIB_TO_TREE} -t #{timetree} -n #{num} -p #{percent} -s #{shift_percent} #{only_min_arg} #{only_max_arg} | nw_topology -".strip
p cmd
new_tree = ` #{cmd} `

# Find all species.trees files and process them in parallel
species_trees_files = Dir.glob("#{outdir}/**/species.trees")

Parallel.each(species_trees_files, in_processes: cpu) do |file|
  #puts file
  dir_name = File.dirname(file)
  Dir.chdir(dir_name) do
    File.open("species.trees", "w") do |f|
      f.puts "#{tipN}\t1"
      f.puts new_tree
    end
    if is_run_mcmctree
      #system("#{RUN_MCMCTREE_IN_BATCH} --indir . --wait")
      ` #{RUN_MCMCTREE_IN_BATCH} --indir . --wait `
    end
  end
end


