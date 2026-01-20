#! /bin/env ruby


###########################################
require 'getoptlong'
require 'parallel'

require 'Dir'


###########################################
CREATE_HESSIAN = File.expand_path("~/lab-tools/dating/hessian/create_hessian_by_bootstrapping.rb")

infile = nil
outdir = nil
is_force = false

treefile = nil
sim_num = 10
calib_tree = nil
seq_len = 1000
model = 'LG+G'
clock_model = 'IR'
bs = 1000
cpu = 10
thread = 3


###########################################
opts = GetoptLong.new(
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--sim_num', '-n', GetoptLong::REQUIRED_ARGUMENT],
  ['--seq_len', GetoptLong::REQUIRED_ARGUMENT],
  ['-m', GetoptLong::REQUIRED_ARGUMENT],
  ['-b', GetoptLong::REQUIRED_ARGUMENT],
  ['--calibrated_tree', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--thread', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '-t'
      treefile = value # subs_tre
    when '--sim_num', '-n'
      sim_num = value.to_i
    when '--seq_len'
      seq_len = value.to_i
    when '-m'
      model = value
    when '-b'
      bs = value.to_i
    when '--calibrated_tree'
      calib_tree = value
    when '--cpu'
      cpu = value.to_i
    when '--thread'
      thread = value.to_i
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
  end
end


###########################################
mkdir_with_force(outdir, is_force)


###########################################
def do_sim_hessian(model, treefile, seq_len, sub_model, alignment_outdir, clock_model, mcmctree_outdir, calib_tree, bs_inBV_outdir, ref_treefile, bs, cpu, thread, mcmctree_ctl)
  `
    iqtree -af phy --alisim alignment -m #{model} -t #{treefile} --length #{seq_len} --alisim #{alignment_outdir}/alignment
    ruby ~/lab-tools/dating/do_mcmctree.rb --outdir #{mcmctree_outdir} --tree #{calib_tree} -i #{alignment_outdir}/alignment.phy --force --prot --clock #{clock_model} --bsn 1,2,3 --cpu #{thread} --sub_model #{sub_model}
    sed '4!d' #{mcmctree_outdir}/combined/in.BV > #{mcmctree_outdir}/ref.tre
    ruby #{CREATE_HESSIAN} --ali #{alignment_outdir}/alignment.phy --calibrated_tree #{calib_tree} --outdir #{bs_inBV_outdir} --force --ref #{ref_treefile} -b #{bs} --cpu #{thread} -m #{sub_model}+G --mcmctree_ctl #{mcmctree_ctl}
  `
end


###########################################
sub_models = %w[lg wag dayhoff].map(&:downcase)
ranges = Hash.new
#ranges['lg'] = Range.new(1,(sim_num*0.8).round).to_a
ranges['lg'] = Range.new(1,sim_num).to_a
start_ind = ranges['lg'][-1]+1
ranges['wag'] = Range.new(start_ind, start_ind+(sim_num/2).to_i-1).to_a
start_ind = ranges['wag'][-1]+1
ranges['dayhoff'] = Range.new(start_ind, start_ind+(sim_num/2).to_i-1).to_a
p ranges


sub_models.each do |sub_model|
  Parallel.map(ranges[sub_model], in_threads: cpu) do |index|
    sub_outdir = File.join(outdir, index.to_s)
    alignment_outdir = File.join(sub_outdir, 'alignment')
    mcmctree_outdir = File.join(sub_outdir, 'mcmctree')
    bs_inBV_outdir = File.join(sub_outdir, 'bs_inBV')
    mkdir_with_force(alignment_outdir, is_force)
    mkdir_with_force(mcmctree_outdir, is_force)
    mkdir_with_force(bs_inBV_outdir, is_force)

    ref_treefile = File.join(mcmctree_outdir, 'ref.tre')
    mcmctree_ctl = File.join(mcmctree_outdir, 'combined', 'mcmctree.ctl')

    do_sim_hessian(model, treefile, seq_len, sub_model, alignment_outdir, clock_model, mcmctree_outdir, calib_tree, bs_inBV_outdir, ref_treefile, bs, cpu, thread, mcmctree_ctl)
  end
end


