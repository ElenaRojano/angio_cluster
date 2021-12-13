#! /usr/bin/env ruby

##############################################################
# Developed by R. Pagano. Refactored by E. Rojano.
# Code to get diseases and in which clusters are to get cluster IDs and the list of genes by disease
##############################################################

require 'optparse'

#################################
##METHODS
#################################
def load_disease_clusters(input_file)
	disease_clusters = {}
	File.open(input_file).each do |line|
		line.chomp!
		orpha_code, cluster_id = line.split("\t")
		disease_clusters[orpha_code] = cluster_id
	end
	return disease_clusters
end

def get_cluster_genes(orpha_genes_file, disease_clusters)
	cluster_genes = {}
	File.open(orpha_genes_file).each do |line|
		line.chomp!
		next if line.include?('DiseaseID')
		orpha_code, genes = line.split("\t")
		genes_list = genes.split(',')
		cluster_id = disease_clusters[orpha_code]
		unless cluster_id.nil?
			query = cluster_genes[cluster_id]
			if query.nil?
				cluster_genes[cluster_id] = [genes_list]
			else
				query << genes_list
			end
		end
	end
	cluster_genes.delete_if{|cluster, genes_by_disease| genes_by_disease.length < 2} #remove clusters with a single disease 
	return cluster_genes
end

def apply_filters(cluster_genes, filter, min_groups_per_gene)
	saved_genes = {}
	general_stats = Hash.new(0)
	cluster_genes.each do |cluster, genes_by_disease|
		stats = Hash.new(0)
		genes_by_disease.each do |gene_group|
			gene_group.each do |gene| 
				stats[gene] += 1
				general_stats[gene] += 1
			end 
		end
		filtered_genes = []
		stats.each do |gene, number|
			next if number < min_groups_per_gene
			filtered_genes << gene if number.fdiv(genes_by_disease.length) >= filter
		end
		saved_genes[cluster] = filtered_genes
	end
	return saved_genes, general_stats
end


#################################
##OPT-PARSE
#################################

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: #{__FILE__} [options]"

	options[:input_file] = nil
	opts.on("-i", "--input_file PATH", "Input ORPHA-cluster file") do |data|
		options[:input_file] = data
	end

	options[:filter_value] = 0
	opts.on("-F", "--filter_value INTEGER", "Filter value. Default 0.8." ) do |data|
		options[:filter_value] = data.to_f
	end

	options[:min_groups] = 0
	opts.on("-m", "--min_groups INTEGER", "Min. diseases per gene") do |data|
		options[:min_groups] = data.to_i
	end

	options[:output_file] = 'output_file.txt'
	opts.on("-o", "--output_file PATH", "Output file") do |data|
		options[:output_file] = data
	end

	options[:orpha_genes] = nil
	opts.on("-t", "--orpha_genes PATH", "ORPHA-genes file (genes separated by commas") do |data|
		options[:orpha_genes] = data
	end

end.parse!

#################################
##MAIN
#################################

# Clusters with a single disease are removed
# options[:filter_value] = 0, options[:min_groups] = 0 -> no filters, genes union
# options[:filter_value] = 0, options[:min_groups] = 2 -> one gene in at least two diseases by cluster 
# options[:filter_value] = 0.6, options[:min_groups] = 2 -> one gene in at least two diseases AND in at least 60% of diseases by cluster

disease_clusters = load_disease_clusters(options[:input_file])
cluster_genes = get_cluster_genes(options[:orpha_genes], disease_clusters)
saved_genes, gene_stats = apply_filters(cluster_genes, options[:filter_value], options[:min_groups])

File.open(File.join(File.dirname(options[:output_file]), 'gene_stats.txt'), 'w') do |f|
	f.puts "gene\tfreq"
	gene_stats.each do |gene, number|
		f.puts "#{gene}\t#{number}"
	end
end

File.open(options[:output_file], 'w') do |f|
	final_genes = []
	saved_genes.each do |clusterID, genes|
		unless genes.empty?
			genes.each do |gene|
				f.puts "#{clusterID}\t#{gene}"
			end
		end
	end
end