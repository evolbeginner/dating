#! /bin/env ruby


####################################################
require 'getoptlong'
require 'parallel'


####################################################
indir = nil
models = Array.new
thread = nil
cpu = 1
is_only_root = false
hessian_type = 'SKT2004'
ori_model = 'LG+G'
is_force = false

#cmds = Array.new
dirs = Array.new


####################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['-m', '--model', GetoptLong::REQUIRED_ARGUMENT],
  ['--ori_model', GetoptLong::REQUIRED_ARGUMENT],
  ['--only_root', GetoptLong::NO_ARGUMENT],
  #['--hessian_type', GetoptLong::REQUIRED_ARGUMENT],
  ['--thread', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '--indir'
      indir = value
    when '-m'
      models = value.split(',')
    when '--ori_model'
      ori_model = value
    when '--only_root'
      is_only_root = true
    #when '--hessian_type'
    #  hessian_type = value
    when '--thread'
      thread = value.to_i
    when '--cpu'
      cpu = value.to_i
    when '--force'
      is_force = true
  end
end


####################################################
cmd_files = Dir.glob(File.join(indir, '**/LG+G/', 'cmd'))


# Print the found files
cmd_files.each do |file|
  dir = File.dirname(file)
  dir2 = File.dirname(dir)
  models.each do |m|
    new_dir = File.join(dir2, m)
    if not is_force
      next if Dir.exist?(new_dir)
    else
      `rm -rf #{new_dir}` if Dir.exist?(new_dir)
      p new_dir
    end
    dirs << [dir, new_dir, m]
    #run_cmd
  end
end


dirs.select!{|a| a[0] =~ /root/} if is_only_root

p dirs


####################################################
Parallel.map(dirs, in_processes:cpu) do |dir|
  dir, new_dir, m = dir
  `cp -r #{dir} #{new_dir}`
  root_change_to = File.basename(File.dirname(File.dirname(new_dir)))
  cmd = `cat #{new_dir}/cmd`
  cmd.gsub!(ori_model, m)
  cmd.sub!(/\n/, '')
  cmd.gsub!('/root/', '/'+root_change_to+'/')
  cmd.gsub!(/[-][-]cpu (\d+)/, '--cpu ' + thread.to_s) if not thread.nil?
  cmd =~ /[-][-]outdir (\S+)/

  if m =~ /\.fd$/
    cmd = [cmd, '--hessian_type fd'].join(' ')
    cmd.sub!(/-m (\S+)\.fd/, '-m \1')
    #cmd.sub!(/--outdir (\S+)#{m}(\S+)/, '--outdir ' + '\1'+m+'.fd\2')
  end

  outdir = $1
  `echo \"#{cmd}\" > #{new_dir}/cmd`
  `rm -rf #{outdir}/../combined/`
  `#{cmd}`
  `mv #{outdir}/date/combined/ #{outdir}/../`
end


