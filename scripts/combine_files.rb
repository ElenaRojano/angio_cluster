#! /usr/bin/env ruby

require 'optparse'

#################################
##METHODS
#################################

def load_metrics_file(metrics_file)
	filtered_metrics = {}
	File.open(metrics_file).each do |line|
		line.chomp!
		next if line.include?('group')
		cluster_id, asp_value = line.split("\t")
		filtered_metrics[cluster_id] = asp_value.to_f
	end
	return filtered_metrics
end

def load_clusters_file(clusters_file)
	clustered_genes = {}
	File.open(clusters_file).each do |line|
		line.chomp!
		cluster_id, gene = line.split("\t")
		query = clustered_genes[cluster_id]
		if query.nil?
			clustered_genes[cluster_id] = [gene]
		else
			query << gene
		end		
	end
	return clustered_genes
end

def combine_data(filtered_metrics, clustered_genes, contributing_diseases_per_cluster, output_file)
	storage = []
	clustered_genes.each do |cluster, genes|
		disease_per_cluster = contributing_diseases_per_cluster[cluster]
		asp_value = filtered_metrics[cluster]
		storage << [genes.length, asp_value, disease_per_cluster, cluster] unless asp_value.nil?
	end
	File.open(output_file, 'w') do |f|
		f.puts "clusterSize\taspValue\tdiseasePerCluster\tclusterID"
		storage.each do |genes, asp_value, disease_per_cluster, cluster|
			f.puts "#{genes}\t#{asp_value}\t#{disease_per_cluster}\t#{cluster}"
		end
	end
end

def load_diseases_file(cluster_diseases_file, disease_gene_file, clustered_genes_storage)
	cluster_diseases = {}
	File.open(cluster_diseases_file).each do |line|
		line.chomp!
		disease_id, cluster_id = line.split("\t")
		load_hash(cluster_diseases, cluster_id, disease_id)
	end
	disease_genes = {}
	File.open(disease_gene_file).each do |line|
		line.chomp!
		disease_id, gene_id = line.split("\t")
		load_hash(disease_genes, disease_id, gene_id)
	end
	contributing_diseases_per_cluster = Hash.new(0)
	cluster_diseases.each do |cluster_id, disease_ids|
		disease_ids.each do |disease|
			gene_ids = disease_genes[disease]
			if !gene_ids.nil?
				contributing_diseases_per_cluster[cluster_id] += 1
			end
		end
		contributing_diseases_per_cluster[cluster_id] = contributing_diseases_per_cluster[cluster_id].fdiv(disease_ids.length) * 100
	end
	return contributing_diseases_per_cluster
end

def load_hash(hash_to_fill, key, val)
	query = hash_to_fill[key]
	if query.nil?
		hash_to_fill[key] = [val]
	else
		query << val
	end
end

#################################
##OPT-PARSER
#################################

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: #{__FILE__} [options]"

	options[:diseases_file] = nil
	opts.on("-d", "--diseases_file PATH", "Diseases file input") do |data|
		options[:diseases_file] = data
	end

	options[:metrics_file] = nil
	opts.on("-i", "--metrics_file PATH", "Metric file input") do |data|
		options[:metrics_file] = data
	end

	options[:clusters_file] = nil
	opts.on("-f", "--clusters_file PATH", "Clusters file input") do |data|
		options[:clusters_file] = data
	end

	options[:disease_gene_file] = nil
	opts.on("-g", "--disease_gene_file PATH", "Disease-gene file input") do |data|
		options[:disease_gene_file] = data
	end

	options[:output_file] = 'output.txt'
	opts.on("-o", "--output_file PATH", "Output combined file") do |data|
		options[:output_file] = data
	end
end.parse!

#################################
##MAIN
#################################

filtered_metrics = load_metrics_file(options[:metrics_file])
clustered_genes = load_clusters_file(options[:clusters_file])
contributing_diseases_per_cluster = load_diseases_file(options[:diseases_file], options[:disease_gene_file], clustered_genes)
combine_data(filtered_metrics, clustered_genes, contributing_diseases_per_cluster, options[:output_file])