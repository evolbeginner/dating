#! /bin/env ruby


#####################################################
DIR = File.dirname($0)


#####################################################
require 'getoptlong'
require 'parallel'
require 'colorize'

require 'Dir'


#####################################################
RUBY = 'ruby'

#CREATE_HESSIAN_BS = File.expand_path("~/lab-tools/dating/hessian/create_hessian_by_bootstrapping.rb")
CREATE_HESSIAN_BS = File.join(DIR, 'create_hessian_by_bootstrapping.rb')
#SIM_TREE = File.expand_path("~/lab-tools/dating/hessian/sim_tree.R")
SIM_TREE = File.join(DIR, 'sim_tree.R')

DO_IQTREE_SIM_MCMCTREE = File.join(DIR, 'do_iqtree_sim_mcmctree.sh')
DO_MCMCTREE = File.expand_path("~/lab-tools/dating/do_mcmctree.rb")

#PHYLO_HESSIAN = File.expand_path("~/project/asr/phyloHessianWrapper.rb")
PHYLO_HESSIAN = File.expand_path("~/lab-tools/dating/phyloHessian/phyloHessianWrapper.rb")
#PHYLO_HESSIAN = File.expand_path("phyloHessian-v0.17.8/phyloHessianWrapper.rb")
#PHYLO_HESSIAN = File.join(DIR, '../phyloHessian/phyloHessianWrapper.rb')


#####################################################
def create_pseudo_phylip(ori_phylip, pseudo_phylip)
  `
    sed '1!s/\\(\\s\\+\\).\\+/\\1A/g' #{ori_phylip} > #{pseudo_phylip}
    sed -i '1s/\\S\\+$/1/' #{pseudo_phylip}
  `
end


def create_ref_tre(pseudo_phylip, outdir, tree_indir, clock, bd, bsn)
  `
    #{RUBY} #{DO_MCMCTREE} --outdir #{outdir} --tree_indir #{tree_indir} -i #{pseudo_phylip} --force --prot --clock #{clock} --bsn #{bsn} --bd #{bd} --print 2
    sed '4!d' #{outdir}/combined/in.BV > #{outdir}/../../ref.tre
  `
end


def get_num_sum_of_model(m)
  if m =~ /PMSF/i
    return(1)
  else
    return( 1 + m.count('+') + m.scan(/\d+/).map(&:to_i).sum )
  end
end


def run_mcmctree(outdir, sim_ali_outdir, phylip, clock, bd, bsn, cmd_out_fh)
    cmd = "#{RUBY} #{DO_MCMCTREE} --outdir #{outdir} --tree_indir #{sim_ali_outdir} -i #{phylip} --prot --clock #{clock} --bd #{bd} --bsn #{bsn} --print 2 --force"
    cmd_out_fh.puts cmd
    `#{cmd}`
end


def run_phyloHessian(ori_fasta, ori_unrooted_tree, ph_sub_outdir, ref_tre, real_cpu, model, bd, bsn, clock, sim_ali_outdir, cmd_out_fh)
  cmd_add = ''
  if model =~ /PMSF/i
    model = model.split('+').filter{|i| i !~ /PMSF/i}.join('+')
    cmd_add = '--pmsf relaxed'
  end
  cmd = "#{RUBY} #{PHYLO_HESSIAN} -s #{ori_fasta} -t #{ori_unrooted_tree} --outdir #{ph_sub_outdir} --force --reftree #{ref_tre} --cpu #{real_cpu} -m #{model} --bd #{bd} \
        --run_mcmctree --bsn #{bsn} --clock #{clock} --phylip #{sim_ali_outdir}/combined.phy --tree_indir #{sim_ali_outdir} #{cmd_add}"
  cmd_out_fh.puts cmd
  `#{cmd}`
end


def get_bs_models(models)
  bs_models = models.select{|i|i=~/bs_inBV/i}.map{|m|remove_bs_inBV_from_model_name(m)}
  models.reject!{|i|i =~ /bs_inBV/i}
  return([models, bs_models])
end


def remove_bs_inBV_from_model_name(name)
  # LG+G+bs_inBV to LG+G
  name2 = name.split('+').reject{|i|i =~ /bs_inBV/i}.join('+')
  return(name2)
end


def print_processing_time(model, s_time)
  e_time = Time.now
  STDOUT.puts [model.colorize(:green)+':', "Time", model, ((e_time-s_time)/60).round(2)].map(&:to_s).join("\t")
end


#####################################################
def prepare_hessian(sim_ali_outdir, ori_mcmctree_outdir)
  phylip = File.join(sim_ali_outdir,'combined.phy')
  species_tree = File.join(sim_ali_outdir,'species.trees')
  mcmctree_ctl = File.join(ori_mcmctree_outdir, 'mcmctree.ctl')
  return([phylip, species_tree, mcmctree_ctl])
end


def do_create_hessian(bs_models, bs, phylip, species_tree, mcmctree_ctl, ref_tre, cpu, outdir0)
  # outdir0: dating/
  Parallel.map(bs_models, in_threads:cpu) do |bs_model|
    outdir = File.join(outdir0, bs_model+'+bs_inBV')
    sub_cpu = (cpu.to_f/bs_models.size).to_i
    cmd = "#{RUBY} #{CREATE_HESSIAN_BS} --ali #{phylip} --calibrated_tree #{species_tree} --outdir #{outdir} --force --ref #{ref_tre} -b #{bs} --cpu #{sub_cpu} -m #{bs_model} --mcmctree_ctl #{mcmctree_ctl} --run_mcmctree"
    ` #{cmd} >/dev/null `
    ` mv #{outdir}/mcmctree #{outdir}/combined `
  end
end


#####################################################
if $0 == __FILE__

simulated_tree_dir=nil
sl=100
cpu=4
scale=1

models = Array.new

# time unit 100 Ma
birth=1
death=1
rho=1e-3
ntips=10
age=40

mu = -3.7 # mu for lnorm
sd = 0.2 # sd for lnorm
s2 = '' # s2 for AR
# for Gamma
alpha = 2.5
beta = 100

sim_model = 'LG+G'
bs=1000

clock = 'IR'
sim_clock = nil
bsn = '1000,10,500'

# bs_inBV
bs = 1000

is_stop_compare=false

outdir = nil
is_force = false

# by default
models = %w[ori LG+G]
#models = %w[LG+R LG+C20+G LG+C60+G LG+C20+G+PMSF LG+C60+G+PMSF LG+C60+R LG+C60+R+PMSF C60+LG+G]


#####################################################
# Define the options
opts = GetoptLong.new(
  ['-m', '--model', GetoptLong::REQUIRED_ARGUMENT],
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
  ['--alpha', GetoptLong::REQUIRED_ARGUMENT],
  ['--beta', GetoptLong::REQUIRED_ARGUMENT],
  ['--clock', GetoptLong::REQUIRED_ARGUMENT],
  ['--sim_clock', GetoptLong::REQUIRED_ARGUMENT],
  ['--sim_model', GetoptLong::REQUIRED_ARGUMENT],
  ['--bsn', GetoptLong::REQUIRED_ARGUMENT],
  ['-b', '--bs', GetoptLong::REQUIRED_ARGUMENT],
  ['--stop_compare', GetoptLong::NO_ARGUMENT],
  ['--phw', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT]
)

# Parse the options
begin
  opts.each do |opt, value|
    case opt
      when '-m', '--model'
        models = value.split(',')
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
      when '--alpha'
        alpha = value
      when '--beta'
        beta = value
      when '--sim_model'
        sim_model = value
      when '--clock'
        clock = value
      when '--sim_clock'
        sim_clock = value
      when '--bsn'
        bsn = value
      when '-b', '--bs'
        bs = value
      when '--stop_compare'
        is_stop_compare = true
      when '--phw'
        old_verbose = $VERBOSE
        $VERBOSE = nil
        PHYLO_HESSIAN = File.expand_path(value)
        $VERBOSE = old_verbose
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

if sim_clock.nil?
  sim_clock = clock
end


#####################################################
mkdir_with_force(outdir, is_force)
outdirs = Hash.new
outdirs[:sim] = File.join(outdir, 'sim')
outdirs[:dating] = File.join(outdir, 'dating')
outdirs.values.map{|v| mkdir_with_force(v, is_force) }
sim_tree_outdir = File.join(outdirs[:sim], 'tree')
sim_ali_outdir = File.join(outdirs[:sim], 'alignment')

bd = [birth, death, rho].join(',')


#####################################################
ori_phylip = File.join(sim_ali_outdir, 'combined.phy')
pseudo_phylip = File.join(sim_ali_outdir, 'combined-pseudo.phy')
ori_fasta = File.join(sim_ali_outdir, 'combined.fas')
ori_time_tree = File.join(sim_tree_outdir, 'time.tre')
ori_unrooted_tree = File.join(sim_tree_outdir, 'unrooted.tre')

cmd_out_fh1 = File.open(File.join(outdirs[:dating], 'cmd'), 'w')


#####################################################
sim_tree_arg_add = ''

if not simulated_tree_dir.nil? and Dir.exist?(simulated_tree_dir); then
  input_tree = File.join(simulated_tree_dir, 'time.tre')
	`cp #{input_tree} #{sim_tree_outdir}`
  sim_tree_arg_add = "--timetree #{sim_tree_outdir}/time.tre"
end

if sim_clock == 'GAMMA'
  sim_tree_arg_add = [sim_tree_arg_add, '--alpha '+alpha.to_s, '--beta '+beta.to_s].join(' ')
end

s2_arg = s2 == '' ? '' : s2
cmd = " Rscript #{SIM_TREE} -n #{ntips} -m #{mu} --sd #{sd} #{s2_arg} -b #{birth} -d #{death} --age #{age} --rho #{rho} -o #{sim_tree_outdir} --clock #{sim_clock} #{sim_tree_arg_add} "
cmd_out_fh1.puts cmd + "\n\n"
`#{cmd}`


#####################################################
# generate aln
cmd = "bash #{DO_IQTREE_SIM_MCMCTREE} --force --outdir #{sim_ali_outdir} --indir #{sim_tree_outdir} -m #{sim_model} --length #{sl}"
#cmd_out_fh1.puts cmd + "\n\n"
`#{cmd}`


#####################################################
# create a pseudo alignment of one site per species, in order to fast calculate in.BV and get ref.tre
create_pseudo_phylip(ori_phylip, pseudo_phylip)

# create ref.tre
create_ref_tre(pseudo_phylip, File.join(outdirs[:dating], 'test'), sim_ali_outdir, clock, bd, '1,2,3')
ref_tre = File.join(outdir, 'ref.tre')

#models = models.push(sim_model)
models.uniq!
# get bs_models
models, bs_models = get_bs_models(models)
plus_sign_count = models.map{|m| get_num_sum_of_model(m) }.sum

cmd_out_fh1.close


#####################################################
puts (Time.now).to_s.colorize(:blue)
Parallel.map(models, in_processes: cpu) do |model|
  s_time = Time.now
  real_cpu = (get_num_sum_of_model(model) * cpu.to_f/plus_sign_count).ceil
  sub_outdir = File.join(outdirs[:dating], model)
  mkdir_with_force(sub_outdir)
  sub_cmd_out_fh = File.open(File.join(sub_outdir, 'cmd'), 'w')

  if model == 'ori'
    run_mcmctree(sub_outdir, sim_ali_outdir, "#{sim_ali_outdir}/combined.phy", clock, bd, bsn, sub_cmd_out_fh)
    print_processing_time(model, s_time)
    phylip, species_tree, mcmctree_ctl = prepare_hessian(sim_ali_outdir, sub_outdir+'/combined')
    do_create_hessian(bs_models, bs, phylip, species_tree, mcmctree_ctl, ref_tre, 
      (cpu/2).floor, outdirs[:dating])
  else
    ph_sub_outdir = File.join(sub_outdir, 'ph')
    run_phyloHessian(ori_fasta, ori_unrooted_tree, ph_sub_outdir, ref_tre, real_cpu, model, bd, bsn, clock, sim_ali_outdir, sub_cmd_out_fh)
    ` rm -rf #{sub_outdir}/combined*; mv #{ph_sub_outdir}/date/* #{sub_outdir} `
  end

  print_processing_time(model, s_time)
  sub_cmd_out_fh.close
end


cmd_out_fh1.close

figtrees = models.select{|m|%w[ori LG+G].include?(m)}.map{|m| File.join(outdirs[:dating], m, 'combined/figtree.nwk') }
`
  Rscript ~/project/Rhizobiales/scripts/dating/hessian/calculate_branch_score_dist.R #{figtrees[0]} #{figtrees[1]} 2>/dev/null
  Rscript ~/project/Rhizobiales/scripts/dating/graph/convergence_plot_two_trees.R -i #{figtrees[0]} -j #{figtrees[1]} -o #{outdirs[:dating]}/convergence.pdf 2>/dev/null
`

# __FILE__
end


