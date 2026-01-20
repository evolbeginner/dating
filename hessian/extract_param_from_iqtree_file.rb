#!/usr/bin/env ruby
# frozen_string_literal: true

require 'getoptlong'

######################################################
# Command-line options
######################################################
opts = GetoptLong.new(
  ['--iqtree', '-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--help',   '-h', GetoptLong::NO_ARGUMENT]
)

iqtree_file = nil

opts.each do |opt, arg|
  case opt
  when '--iqtree'
    iqtree_file = arg
  when '--help'
    puts <<~HELP
      Usage:
        ruby parse_iqtree.rb -i file.iqtree

      Options:
        -i, --iqtree FILE    IQ-TREE .iqtree file to parse
        -h, --help           Show this help message
    HELP
    exit
  end
end

abort("ERROR: missing -i / --iqtree option") unless iqtree_file
abort("ERROR: file not found: #{iqtree_file}") unless File.exist?(iqtree_file)

######################################################
# Data containers
######################################################
freqs        = {}     # amino-acid frequencies
pis          = []     # frequencies as array
weights      = {}     # indexed mixture components (CkpiN)
extra_weight = nil    # standalone LG_F+F component

pinv  = nil
gamma = nil
model = nil

######################################################
# Parse IQ-TREE file
######################################################
File.foreach(iqtree_file) do |line|
  # Model name
  if line =~ /^Model of substitution:\s+(\S+)/
    model = Regexp.last_match(1)
  end

  # Frequencies (+F)
  if line =~ /^\s*pi\((\w)\)\s*=\s*([\d.]+)/
    aa  = Regexp.last_match(1)
    val = Regexp.last_match(2).to_f
    freqs[aa] = val
  end

  # Proportion of invariant sites (+I)
  if line =~ /^Proportion of invariable sites:\s+([\d.]+)/
    pinv = Regexp.last_match(1).to_f
  end

  # Gamma shape (+G)
  if line =~ /^Gamma shape alpha:\s+([\d.]+)/
    gamma = Regexp.last_match(1).to_f
  end

  # Profile mixture components: LG_F+FCkpiN
  if line =~ /^\s*\d+\s+LG_F\+FC(\d+)pi(\d+)\s+[\d.]+\s+([\d.]+)/
    idx = Regexp.last_match(2).to_i
    w   = Regexp.last_match(3).to_f
    weights[idx] = w
  end

  # Plain LG_F+F component → extra mixture
  if line =~ /^\s*\d+\s+LG_F\+F\s+[\d.]+\s+([\d.]+)/
    extra_weight = Regexp.last_match(1).to_f
  end
end

######################################################
# Output
######################################################
puts "Model            : #{model}" if model
puts "Proportion +I    : #{pinv}"  if pinv
puts "Gamma shape +G   : #{gamma}" if gamma

puts "Frequencies (+F):"
freqs.each do |aa, val|
  puts format("  %s: %.6f", aa, val)
  pis << val
end

puts
puts "Frequencies as string:"
puts pis.map { |v| format('%.6f', v) }.join(' ')

# IQ-TREE model string
if model && pinv && gamma
  base_model = model.split('+').first
  iqtree_model = format(
    '%s+F+I{%.6f}+G4{%.3f}',
    base_model, pinv, gamma
  )

  puts
  puts "IQ-TREE -m string:"
  puts %(-m "#{iqtree_model}")
end

# Mixture weights
unless weights.empty?
  max_idx = weights.keys.max
  weight_array = (1..max_idx).map { |i| weights[i] || 0.0 }

  # Append LG_F+F component if present
  weight_array << extra_weight if extra_weight

  puts
  puts "Mixture weights (space-separated):"
  puts weight_array.map { |w| format('%.6f', w) }.join(' ')
end

