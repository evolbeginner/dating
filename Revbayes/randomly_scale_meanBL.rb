#! /bin/env ruby


##########################################################
require 'getoptlong'

require 'Dir'


##########################################################
TREEIO = File.expand_path("~/tools/self_bao_cun/phylo_mini/treeio.rb")


##########################################################
infile = nil
outdir = nil
is_force = false
bl_scale_arg = ''
bl_times_arg = '--bl_times 1'
n = 0

rand_tree_strs = Array.new


##########################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--bl_scale', GetoptLong::REQUIRED_ARGUMENT],
  ['--bl_times', GetoptLong::REQUIRED_ARGUMENT],
  ['-n', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--outdir'
      outdir = value
    when '--bl_scale'
      bl_scale_arg = "--bl_scale #{value}"
    when '--bl_times'
      bl_times_arg = "--bl_times #{value}"
    when '--force'
      is_force = true
    when '-n'
      n = value.to_i
  end
end


##########################################################
mkdir_with_force(outdir, is_force)
nwk_file = File.join(outdir, 'haha.tre')


##########################################################
# convert nexus to nwk
`sed "4!d" #{infile} | sed 's/[^()]\\+\(/(/' > #{nwk_file}`

`sed "s/\\[/!/g" -i #{nwk_file}`
`sed "s/\\]/?/g" -i #{nwk_file}`

# randomize bl
1.upto(n).each do |i|
  rand_file = File.join(outdir, 'rand'+i.to_s+'.tre')
  `ruby #{TREEIO} -i #{nwk_file} #{bl_scale_arg} > #{rand_file}`
  `ruby #{TREEIO} -i #{nwk_file} #{bl_times_arg} | sponge #{rand_file}`
  `sed -i 's/[(]//; s/);/;/' #{rand_file}`

  `sed "s/!/\\[/g" -i #{rand_file}`
  `sed "s/?/\\]/g" -i #{rand_file}`
  i_next = i + 1
  `i_next=#{i_next}; sed -i "s/[(]/tree TREE#{i_next} = (/" #{rand_file} `

  rand_tree_strs << text = File.read(rand_file)
end


##########################################################
in_fh = File.open(infile, 'r')
out_nexus_file = File.join(outdir, 'out.nexus')
out_fh = File.open(out_nexus_file, 'w')

in_fh.each do |line|
  line.chomp!
  if $. == 5
    rand_tree_strs.each do |str|
      out_fh.puts str
    end
    out_fh.puts "End;"; break
  end
  out_fh.puts line
end

in_fh.close
out_fh.close


