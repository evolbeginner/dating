#! /bin/env ruby


#####################################################
# 2024-11-12


#####################################################
DIR = File.dirname($0)


#####################################################
require 'getoptlong'
require 'parallel'
require 'colorize'

require 'Dir'


#####################################################
RUBY = 'ruby'

CREATE_HESSIAN_BS = File.expand_path("~/lab-tools/dating/hessian/create_hessian_by_bootstrapping.rb")
SIM_TREE = File.expand_path("~/lab-tools/dating/hessian/sim_tree.R")

DO_IQTREE_SIM_MCMCTREE = File.join(DIR, 'do_iqtree_sim_mcmctree.sh')
DO_MCMCTREE = File.expand_path("~/lab-tools/dating/do_mcmctree.rb")

PHYLO_HESSIAN = File.expand_path("~/project/asr/phyloHessianWrapper.rb")


#####################################################
def create_pseudo_phylip(ori_phylip, pseudo_phylip)
  `
    sed '1!s/\\(\\s\\+\\).\\+/\\1A/g' #{ori_phylip} > #{pseudo_phylip}
    sed -i '1s/\\S\\+$/1/' #{pseudo_phylip}
  `
end


def create_ref_tre(pseudo_phylip, outdir, tree_indir, clock, bsn='1,2,3')
  `
    #{RUBY} #{DO_MCMCTREE} --outdir #{outdir} --tree_indir #{tree_indir} -i #{pseudo_phylip} --force --prot --clock #{clock} --bsn #{bsn} --print 2
    sed '4!d' #{outdir}/combined/in.BV > #{outdir}/../../ref.tre
  `
end


def get_num_sum_of_model(m)
  return( 1 + m.count('+') + m.scan(/\d+/).map(&:to_i).sum )
end


#####################################################
if $0 == __FILE__

simulated_tree_dir=nil
sl=100
cpu=4
scale=1

# time unit 100 Ma
birth=1
death=1
rho=1e-3
ntips=10
age=40

mu = -3.7 # mu for lnorm
sd = 0.2 # sd for lnorm
s2 = 0.032 # s2 for AR model

sim_model = 'LG+G'
bs=1000

clock = 'IR'
bsn = '1000,10,500'

is_stop_compare=false

outdir = nil
is_force = false


#####################################################
# Define the options
opts = GetoptLong.new(
  ['--simulated_tree_dir', GetoptLong::REQUIRED_ARGUMENT],
  ['--sl', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--scale', GetoptLong::REQUIRED_ARGUMENT],
  ['--birth', GetoptLong::REQUIRED_ARGUMENT],
  ['--death', GetoptLong::REQUIRED_ARGUMENT],
  ['--age', GetoptLong::REQUIRED_ARGUMENT],
  ['--rho', GetoptLong::REQUIRED_ARGUMENT],
  ['--ntips', GetoptLong::REQUIRED_ARGUMENT],
  ['--mu', GetoptLong::REQUIRED_ARGUMENT],
  ['--sd', GetoptLong::REQUIRED_ARGUMENT],
  ['--s2', GetoptLong::REQUIRED_ARGUMENT],
  ['--sim_model', GetoptLong::REQUIRED_ARGUMENT],
  ['--clock', GetoptLong::REQUIRED_ARGUMENT],
  ['--bsn', GetoptLong::REQUIRED_ARGUMENT],
  ['-b', GetoptLong::REQUIRED_ARGUMENT],
  ['--bs', GetoptLong::REQUIRED_ARGUMENT],
  ['--stop_compare', GetoptLong::NO_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT]
)

# Parse the options
begin
  opts.each do |opt, value|
    case opt
    when '--simulated_tree_dir'
      simulated_tree_dir = value
    when '--sl'
      sl = value
    when '--cpu'
      cpu = value.to_i
    when '--scale'
      scale = value
    when '--birth'
      birth = value
    when '--death'
      death = value
    when '--age'
      age = value
    when '--rho'
      rho = value
    when '--ntips'
      ntips = value
    when '--mu'
      mu = value
    when '--sd'
      sd = value
    when '--s2'
      s2 = value
    when '--sim_model'
      sim_model = value
    when '--clock'
      clock = value
    when '--bsn'
      bsn = value
    when '-b', '--bs'
      bs = value
    when '--stop_compare'
      is_stop_compare = true
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
    end
  end
rescue GetoptLong::InvalidOption => e
  STDERR.puts "Wrong argument #{e.message}!"
  exit 1
end


#####################################################
mkdir_with_force(outdir, is_force)
outdirs = Hash.new
outdirs[:sim] = File.join(outdir, 'sim')
outdirs[:dating] = File.join(outdir, 'dating')
outdirs.values.map{|v| mkdir_with_force(v, is_force) }

sim_tree_outdir = File.join(outdirs[:sim], 'tree')
sim_ali_outdir = File.join(outdirs[:sim], 'alignment')


#####################################################
sim_tree_arg_add = ''
if not simulated_tree_dir.nil? and Dir.exist?(simulated_tree_dir); then
  input_tree = File.join(simulated_tree_dir, 'time.tre')
	`cp #{input_tree} #{sim_tree_outdir}`
  sim_tree_arg_add = "--timetree #{sim_tree_outdir}/time.tre"
end
`Rscript #{SIM_TREE} -n #{ntips} -m #{mu} --sd #{sd} --s2 #{s2} -b #{birth} -d #{death} --age #{age} --rho #{rho} -o #{sim_tree_outdir} --clock #{clock} #{sim_tree_arg_add}`


#####################################################
# generate aln
`bash #{DO_IQTREE_SIM_MCMCTREE} --force --outdir #{sim_ali_outdir} --indir #{sim_tree_outdir} -m #{sim_model} --length #{sl}`


#####################################################
# create a pseudo alignment of one site per species, in order to fast calculate in.BV and get ref.tre
ori_phylip = File.join(sim_ali_outdir, 'combined.phy')
pseudo_phylip = File.join(sim_ali_outdir, 'combined-pseudo.phy')
ori_fasta = File.join(sim_ali_outdir, 'combined.fas')
ori_time_tree = File.join(sim_tree_outdir, 'time.tre')
ori_unrooted_tree = File.join(sim_tree_outdir, 'unrooted.tre')
create_pseudo_phylip(ori_phylip, pseudo_phylip)

# create ref.tre
create_ref_tre(pseudo_phylip, File.join(outdirs[:dating], 'test'), sim_ali_outdir, clock)
ref_tre = File.join(outdir, 'ref.tre')

models = %w[ori LG LG+G EX2+G LG+C20+G LG+C40+G LG+C60+G]
models = models.push(sim_model)
models.uniq!
plus_sign_count = models.map{|m| get_num_sum_of_model(m) }.sum


#####################################################
puts (Time.now).to_s.colorize(:blue)
Parallel.map(models, in_processes: cpu) do |model|
  s_time = Time.now
  real_cpu = (get_num_sum_of_model(model) * cpu.to_f/plus_sign_count).ceil

  if model == 'ori'
    `#{RUBY} #{DO_MCMCTREE} --outdir #{outdirs[:dating]}/ori --tree_indir #{sim_ali_outdir} -i #{sim_ali_outdir}/combined.phy --prot --clock #{clock} --bsn #{bsn} --print 2 --force`
  else
    sub_outdir = File.join(outdirs[:dating], model)
    ph_sub_outdir = File.join(outdirs[:dating], model, 'ph')

    cmd = "#{RUBY} #{PHYLO_HESSIAN} -s #{ori_fasta} -t #{ori_unrooted_tree} --outdir #{ph_sub_outdir} --force --reftree #{ref_tre} --cpu #{real_cpu} -m #{model} \
        --run_mcmctree --bsn #{bsn} --clock #{clock} --phylip #{sim_ali_outdir}/combined.phy --tree_indir #{sim_ali_outdir} "
    puts cmd

    ` rm -rf #{sub_outdir}/combined*; mv #{ph_sub_outdir}/date/* #{sub_outdir} `

    #inBV = File.join(ph_sub_outdir, 'inBV', 'in.BV')
    #puts (Time.now).to_s.colorize(:blue)
    #add_argu = "--inBV #{inBV}"
    #puts "#{RUBY} #{DO_MCMCTREE} --outdir #{sub_outdir} --tree_indir #{sim_ali_outdir} -i #{sim_ali_outdir}/combined.phy --prot --clock IR --bsn #{bsn} --print 2 #{add_argu} --tolerate"
    #` #{RUBY} #{DO_MCMCTREE} --outdir #{sub_outdir} --tree_indir #{sim_ali_outdir} -i #{sim_ali_outdir}/combined.phy --prot --clock IR --bsn #{bsn} --print 2 #{add_argu} --tolerate; mv #{ph_sub_outdir} #{sub_outdir}/combined `
  end

  e_time = Time.now
  puts model.colorize(:green)
  puts ["Time", model, ((e_time-s_time)/60).round(2)].map(&:to_s).join("\t")
end

figtrees = models.map{|m| File.join(outdirs[:dating], m, 'combined/figtree.nwk') }
puts "Rscript ~/project/Rhizobiales/scripts/dating/hessian/calculate_branch_score_dist.R #{figtrees[0]} #{figtrees[1]}; Rscript ~/project/Rhizobiales/scripts/dating/graph/convergence_plot_two_trees.R -i #{figtrees[0]} -j #{figtrees[1]} -o #{outdirs[:dating]}/convergence.pdf"
`
  Rscript ~/project/Rhizobiales/scripts/dating/hessian/calculate_branch_score_dist.R #{figtrees[0]} #{figtrees[1]} 2>/dev/null
  Rscript ~/project/Rhizobiales/scripts/dating/graph/convergence_plot_two_trees.R -i #{figtrees[0]} -j #{figtrees[1]} -o #{outdirs[:dating]}/convergence.pdf 2>/dev/null
`

# __FILE__
end


