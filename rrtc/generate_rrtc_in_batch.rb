#! /bin/env ruby


#################################################
require 'parallel'
require 'getoptlong'
require 'fileutils'

require 'Dir'


#################################################
DO_RRTC = File.expand_path("~/project/Rhizobiales/scripts/dating/rrtc/do_rrtc.rb")
RUN_MCMCTREE = File.expand_path("~/project/Rhizobiales/scripts/dating/run_mcmctree_in_batch.sh")
IS_STRICTS = [false, true]

TYPES = %w[marginal joint]


#################################################
def copy_others_for_mcmctree_print_minus1(indir, outdir)
  mcmctree_ctl = File.join(indir, 'mcmctree.ctl')
  FileUtils.cp(mcmctree_ctl, outdir)
  FileUtils.cp(indir+'/combined.phy', outdir)
  FileUtils.cp(indir+'/in.BV', outdir)
  FileUtils.cp(indir+'/species.trees', outdir)
  `sed -i 's/print.\\+/print = -1/' #{outdir}/mcmctree.ctl`
end


#################################################
mcmctree_indir = nil
rrtc_indir = nil
is_force = false
cpu = 4


#################################################
opts = GetoptLong.new(
  ['--mcmctree_indir', '--mcmctree_dir', GetoptLong::REQUIRED_ARGUMENT],
  ['--rrtc_indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '--mcmctree_indir', '--mcmctree_dir'
      mcmctree_indir = value
    when '--rrtc_indir'
      rrtc_indir = value
    when '--force'
      is_force = true
    when '--cpu'
      cpu = value.to_i
  end
end


#################################################
mcmctxt = File.join(mcmctree_indir, 'mcmc.txt')
mcmctree_out = File.join(mcmctree_indir, 'out')


#################################################
rrtc_indir_basenames = Dir.glob(rrtc_indir + '/*').select{|i|File.basename(i) =~ /^official/}.map{|i|File.basename(i)}

#Dir.foreach(rrtc_indir) do |b|
Parallel.map(rrtc_indir_basenames, in_threads: cpu) do |b|
  TYPES.each do |type|
    IS_STRICTS.each do |is_strict|
      strict_suffix = is_strict ? '.strict' : ''
      strict_arg = is_strict ? '--strict' : ''

      filter_outdir = File.join(mcmctree_indir, 'rrtc_res', b, type+strict_suffix)
      rrtc_indir2 = File.join(rrtc_indir, b, type)

      mkdir_with_force(filter_outdir, is_force)
      output_mcmctxt = File.join(filter_outdir, 'mcmc.txt')

      copy_others_for_mcmctree_print_minus1(mcmctree_indir, filter_outdir)
      `ruby #{DO_RRTC} --mcmctxt #{mcmctxt} -i #{mcmctree_out} --rrtc #{rrtc_indir2} --is_rrtc T #{strict_arg} > #{output_mcmctxt}`
      `cd #{filter_outdir}; bash #{RUN_MCMCTREE} --indir . --nohup`
    end
  end
end


