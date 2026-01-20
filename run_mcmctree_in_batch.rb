#! /bin/env ruby


##################################################
DIR ||= File.dirname(__FILE__)


##################################################
require_relative 'do_mcmctree.rb'
require 'getoptlong'
require 'parallel'


##################################################
#OUTPUT_MCMCTREE_RATE = File.expand_path("~/lab-tools/dating/output_mcmctree_rate.rb")
OUTPUT_MCMCTREE_RATE = File.join(DIR, 'output_mcmctree_rate.rb')
FIGTREE2TREE = File.join(DIR, 'figtree2tree.sh')


##################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--nohup', GetoptLong::NO_ARGUMENT],
  ['--hpc', '--HPC', GetoptLong::NO_ARGUMENT],
  ['--wait', GetoptLong::NO_ARGUMENT],
  ['--pre', '--prefix', GetoptLong::REQUIRED_ARGUMENT],
  ['-w', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT]
)

indir = nil
type = ''
prefix = 'mib'
w_arg = ''
cpu = 1

opts.each do |opt, arg|
  case opt
  when '--indir'
    indir = arg
  when '--nohup'
    type = 'nohup'
  when '--hpc'
    type = 'hpc'
  when '--wait'
    type = 'wait'
  when '--pre', '--prefix'
    prefix = arg
  when '-w'
    w_arg = "-w #{arg}"
  when '--cpu'
    cpu = arg.to_i
  end
end

if indir.nil? || indir.empty?
  puts 'indir not given! Exiting ......'
  exit(1)
end


# Main processing
mcmctree_files = Dir.glob(File.join(indir, '**', 'mcmctree.ctl'))

cmd = "[ -f FigTree.tre ] && rm FigTree.tre; [ -f figtree.nwk ] && rm figtree.nwk; rm rate*.tre 2>/dev/null; rm mcmc.txt* 2>/dev/null; mcmctree > mcmctree.final; bash #{FIGTREE2TREE} -i FigTree.tre > figtree.nwk; ln -s out out.txt 2>/dev/null; #{OUTPUT_MCMCTREE_RATE}; tar czvf mcmc.txt.gz mcmc.txt && rm mcmc.txt"


Parallel.each(mcmctree_files, in_threads: cpu) do |ctl_file|
  dir = File.dirname(ctl_file)
  `cd #{dir}; #{cmd};`
end


