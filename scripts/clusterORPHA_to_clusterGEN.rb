#! /usr/bin/env ruby

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
	return cluster_genes
end

def apply_filters(cluster_genes, filter, min_groups_per_gene)
	saved_genes = {}
	cluster_genes.each do |cluster, gene_groups|
		next if gene_groups.length == 1
		stats = Hash.new(0)
		gene_groups.each do |gene_group|
			gene_group.each do |gene| 
				stats[gene] += 1
			end 
		end
		filtered_genes = []
		stats.each do |gene, number|
			next if number < min_groups_per_gene
			filtered_genes << gene if number.fdiv(gene_groups.length) >= filter
		end
		saved_genes[cluster] = filtered_genes
	end
	return saved_genes
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
	opts.on("-m", "--min_groups INTEGER", "Min. groups per gene") do |data|
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

# options[:filter_value] = 0, options[:min_groups] = 0 -> no filters
# options[:filter_value] = 1, options[:min_groups] = 0 -> 
# options[:filter_value] = 1, options[:min_groups] = 0.8 -> eliminate genes not presented in 80% of diseases

disease_clusters = load_disease_clusters(options[:input_file])
cluster_genes = get_cluster_genes(options[:orpha_genes], disease_clusters)
saved_genes = apply_filters(cluster_genes, options[:filter_value], options[:min_groups])

File.open(options[:output_file], 'w') do |f|
	final_genes = []
	saved_genes.each do |clusterID, genes|
		unless genes.empty?
			f.puts "#{clusterID}\t#{genes.uniq.join(',')}"
		end
	end
end