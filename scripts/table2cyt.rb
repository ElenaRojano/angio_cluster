#! /usr/bin/env ruby

require 'optparse'
require 'json'

###############################################################
## METHODS
###############################################################
def load_pairs(input, cols, types)
	pairs = []
	count = 0
	node_ids = {}
	nodes = []
	File.open(input).each do |line|
		fields = line.chomp.split("\t")
		node_cols = cols.map{|c| fields[c]}
		node_cols.map!{|nc| nc.split(',')}
		node_cols.each_with_index do |nodes_A, i|
			nodes_B = node_cols[i+1]
			nodes_A.each do |node_A|
				next if node_A == '-'
				query_node = node_ids[node_A]
				if query_node.nil?
					node_ids[node_A] = count.to_s
					add_node(nodes, node_A, count.to_s, types[i])
					count += 1
				end
				if !nodes_B.nil?
					nodes_B.each do |node_B|
						next if node_B == '-'
						pairs << [node_A, node_B]
					end
				end
			end
		end
	end
	return pairs, node_ids, nodes, count
end

def add_node(nodes, name, count, type)
	node = {
		'data' => {
			'id' => count,
			'name' => name,
		}
	}
	node['data']['type'] = type if !type.nil?
	nodes << node
end

def pairs2cys(pairs, node_ids, nodes, count)
	edges = []
	pairs.each do |node_A, node_B|
		edges << {
			'data' => {
				'id' => count.to_s,
				'source' => node_ids[node_A],
				'target' => node_ids[node_B],
				"interaction" => "-",
        "weight" => 1.0
			}
		}
		count +=1
	end
	cys = {
		'elements' => {
			'nodes' => nodes, 
			'edges' => edges
		}
	}
	return cys
end

###############################################################
## OPTPARSE
###############################################################
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

  options[:input] = nil
  opts.on("-i", "--input_file PATH", "Path to input file") do |item|
    options[:input] = item
  end

  options[:output] = nil
  opts.on("-o", "--output_file PATH", "Path to output file") do |item|
    options[:output] = item
  end

  options[:cols] = [0, 1]
  opts.on("-c", "--cols STRING", "Columns with network nodes. 0 based. Default, 0,1") do |item|
    options[:cols] = item.split(',').map{|st| st.to_i}
  end

  options[:types] = []
  opts.on("-t", "--types STRING", "node types, one for each selected col. 0 based. Default, 0,1") do |item|
    options[:types] = item.split(',')
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

###############################################################
## MAIN
###############################################################
pairs, node_ids, nodes, count = load_pairs(options[:input], options[:cols], options[:types])
cys_net = pairs2cys(pairs, node_ids, nodes, count)

File.open(options[:output]+ '.cyjs', 'w'){|f| f.print JSON.pretty_generate(cys_net)}