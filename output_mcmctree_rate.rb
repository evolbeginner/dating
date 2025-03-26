#! /bin/env ruby


#####################################
require 'getoptlong'
require 'bio'
require 'bio-nwk'


#####################################
def output_rate()
  output_tree = false
  k = 0
  IO.popen("grep -A1 rategram out.txt 2>/dev/null") do |grep_output|
    grep_output.each_line do |line|
      line.chomp!
      if output_tree
        File.write("rate#{k}.tre", line) # Create or overwrite the file
      end
      if line.include?("locus")
        k += 1
        output_tree = true
      else
        output_tree = false
      end
    end
  end
  
  average_branch_lengths("rate*.tre", 'rate.tre')
end


def average_branch_lengths(file_pattern, outfile)
  files = Dir.glob(file_pattern).reject{ |file| file == 'rate.tre' }
  raise "No files found matching pattern: #{file_pattern}" if files.empty?

  # Read and parse trees with error handling
  trees = files.map do |file|
    begin
      Bio::Newick.new(File.read(file)).tree
    rescue => e
      raise "Error parsing #{file}: #{e.message}"
    end
  end

  # Validate tree consistency
  n_branches = trees[0].nodes.size - 1
  trees.each_with_index do |tree, i|
    if tree.nodes.size - 1 != n_branches
      raise "Tree #{files[i]} has different topology (branch count mismatch)"
    end
  end

  # Calculate average branch lengths
  sum_branch_lengths = Array.new(n_branches+1, 0.0)
  trees.each do |tree|
    index = 0
    tree.each_edge do |node1, node2, edge|
      index += 1
      dist = edge.distance
      sum_branch_lengths[index] += dist
    end
  end

  avg_branch_lengths = sum_branch_lengths.map { |sum| sum / trees.size }

  # Create averaged tree
  avg_tree = trees.first.dup
  index = 0
  avg_tree.each_edge do |node1, node2, edge|
    index += 1
    edge.distance = avg_branch_lengths[index]
  end

  # Write output with proper file handling
  File.open(outfile, 'w') do |f|
    newick_string = avg_tree.cleanNewick
    f.write(newick_string)
  end
end


#####################################
output_rate()


