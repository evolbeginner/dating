#! /bin/env ruby


##############################################
require 'getoptlong'
require 'bio-nwk'


##############################################
infile = nil
type = 'uniform'


##############################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', '--type', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-t', '--type'
      type = value
  end
end


##############################################
t = getTreeObjs(infile)[0]
t.internal_nodes.each do |node|
  #next if node.isTip?(t)
  taxa = t.twoTaxaNodeName(node).map{|i|i.gsub(' ', '_')}
  times = node.name.split('-')
  calib_name = 'calibrationName=' + [taxa,'split'].flatten.join('-')

  case type
    when 'uniform'
      puts ["!MRCA='" + taxa.join('-') + "'", 'TaxonA='+taxa[0], 'TaxonB='+taxa[1], 'Distribution=uniform mintime='+times[0], 'maxtime='+times[1], calib_name].join(' ')
    when 'normal'
      mean = times.map(&:to_f).sum/2
      std = (times.map(&:to_f)[0] - mean).abs/1.96
      puts ["!MRCA='" + taxa.join('-') + "'", 'TaxonA='+taxa[0], 'TaxonB='+taxa[1], 'Distribution=normal mean='+mean.to_s, 'stddev='+std.to_s, calib_name].join(' ')
    else
      raise "unknown type #{type}"
  end
  # !MRCA='t10-t7' TaxonA='t10' TaxonB='t7' Distribution=normal mean=2.25000000 stddev=0.15000000 calibrationName='t10-t7-split';
  # !MRCA='t9-t8' TaxonA='t9' TaxonB='t8' Distribution=uniform mintime=1.00000000 maxtime=2.00000000 calibrationName='t9-t8-split';
end


