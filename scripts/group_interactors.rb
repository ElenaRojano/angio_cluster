#! /usr/bin/env ruby
# Load filter STRING relationships and clusters file to select the top N nodes connecting to each gene.

require 'optparse'

#################################
##METHODS
#################################

def load_string_file(file)
	string_data = {}
	File.open(file).each do |line|
		line.chomp!
		next if line.include?('protein')
		geneA, geneB, comb_score = line.split("\t")
		query = string_data[geneA]
		if query.nil?
			string_data[geneA] = [[geneB, comb_score.to_i]]
		else
			query << [geneB, comb_score.to_i]
		end
	end	
	string_data.each do |geneA, nodes_conn|
		string_data[geneA] = nodes_conn.sort{|a, b| a[1] <=> b[1]}
	end
	return string_data
end


def add_nodes(string_data, input_clusters, nodes_number)
	genes_by_cluster = {}
	File.open(input_clusters).each do |line|
		line.chomp!
		cluster, gene = line.split("\t")
		nodes_by_gene = string_data[gene]
		unless nodes_by_gene.nil?
			nodes_associated = nodes_by_gene[0..nodes_number-1].map{|a| a[0]} << gene
			query = genes_by_cluster[cluster]
			if query.nil?
				genes_by_cluster[cluster] = [nodes_associated]
			else
				query << nodes_associated
			end
		end
	end 
	return genes_by_cluster
end

#################################
##OPT-PARSE
#################################

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: #{__FILE__} [options]"

	options[:input_clusters] = nil
	opts.on("-c", "--input_clusters PATH", "Input clusters file") do |data|
		options[:input_clusters] = data
	end	

	options[:input_file] = nil
	opts.on("-i", "--input_file PATH", "Input STRING file") do |data|
		options[:input_file] = data
	end

	options[:nodes_number] = 20
	opts.on("-n", "--nodes_number INTEGER", "Number of top nodes. Default 20." ) do |data|
		options[:nodes_number] = data.to_f
	end

	options[:output_file] = 'output_file.txt'
	opts.on("-o", "--output_file PATH", "Output file") do |data|
		options[:output_file] = data
	end

	opts.on_tail("-h", "--help", "Show this message") do
    	puts opts
   		exit
  	end

end.parse!

#################################
##MAIN
#################################

string_data = load_string_file(options[:input_file])
genes_by_cluster = add_nodes(string_data, options[:input_clusters], options[:nodes_number])

File.open(options[:output_file], 'w') do |f|
	genes_by_cluster.each do |cluster, genes|
		genes.each do |genes_list|
			genes_list.each do |gene|
				f.puts "#{cluster}\t#{gene}"
			end
		end
	end
end