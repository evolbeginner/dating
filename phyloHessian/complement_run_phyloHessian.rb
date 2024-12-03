#! /bin/env ruby


###########################################################
require 'getoptlong'
require 'parallel'


###########################################################
def get_outdir(cmd)
 cmd =~ /[-][-]outdir (\S+)/
 outdir = $1
 return(outdir)
end


###########################################################
indir = nil
cpu = 1
is_run = false


###########################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', GetoptLong::REQUIRED_ARGUMENT],
  ['--run', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--indir'
      indir = value
    when '--cpu'
      cpu = value.to_i
    when '--run'
      is_run = true
  end
end


###########################################################
dirs = `for i in \`find #{indir} -name combined\`; do if [ ! -f $i/figtree.nwk ]; then echo $i; fi; done`.split("\n")

puts dirs.join("\n")

exit if ! is_run

Parallel.map(dirs, in_processes: cpu) do |d|
  begin
    parent_dir = File.dirname(d)
    cmd_infile = File.join(parent_dir, 'cmd')
    cmd = `cat #{cmd_infile}`.chomp
    outdir = get_outdir(cmd)
    combined_dir = File.join(parent_dir, 'combined')
    ` #{cmd} `
    `rm -r #{combined_dir}; mv #{outdir}/date/combined/ #{parent_dir}`
  rescue => e
    puts e
  end
end



