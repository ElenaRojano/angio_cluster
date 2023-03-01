#! /usr/bin/env ruby

require 'optparse'
#################################
##METHODS
#################################

def load_tabular(file)
	data = []
	File.open(file).each do |line|
		data << line.chomp.split("\t")
	end
	return data
end

def load_clusters(file, nodes)
	clusters = {}
	load_tabular(file).each do |cl_id, node|
		if nodes[node]
			add_hash(cl_id, node, clusters)
		else
			puts "#{node} node id from cluster #{cl_id} not exists in network"
		end
	end
	return clusters
end

def load_paths(paths_file, thr)
	path_data = {}
	nodes = {}
	load_tabular(paths_file).each do |fields|
		source, target = fields.shift(2)
		nodes[source] = true
		nodes[target] = true
		if !thr.nil?
			sphere = fields[5].to_i
			if sphere <= thr
				fields[5] = sphere
			else
				next
			end
		end
		fields[0] = fields[0].to_f #Biological distance
		fields[6] = fields[6].split(']').map{|g| g.split('[').first} #Route
		add_hash(source, {target => fields}, path_data)
	end
	return path_data, nodes
end

def load_paths_simple(paths_file)
	path_data = {}
	nodes = {}
	load_tabular(paths_file).each do |fields|
		source, target = fields.shift(2)
		nodes[source] = true
		nodes[target] = true
		fields[0] = fields[0].to_f #Biological distance
		fields[6] = fields[1].split(',') #Route
		add_hash(source, {target => fields}, path_data)
	end
	return path_data, nodes
end


def write_tabular(data, file)
	File.open(file, 'w') do |f|
		data.each do |record|
			f.puts record.join("\t")
		end
	end
end

def write_nested_tabular(data, file, col)
	File.open(file, 'w') do |f|
		data.each do |record|
			items = record[col]
			items.each do |item|
				record[col] = item
				f.puts record.join("\t")
			end
		end
	end
end

def add_hash(key, val, hash)
	query = hash[key]
	if query.nil?
		if val.class == Hash
			hash[key] = val
		else
			hash[key] = [val]
		end
	else
		if val.class == Hash
			query.merge!(val)
		else
			query << val
		end
	end
end

def compact_hgc(input_folder, gene_list=nil)
	all_data = []
	Dir.glob(input_folder).each do |file_path|
		gene = File.basename(file_path, '.txt')
		next if !gene_list.nil? && !gene_list.include?(gene)
		gene_data = load_tabular(file_path)
		gene_data.shift(2) # Remove header and gene self path
		#gene_data.select!{|g| gene_list.include?(g.first)} if !gene_list.nil?
		gene_data.each{|g| g.unshift(gene)}
		all_data.concat(gene_data)
	end
	return all_data
end

def expand_clusters(clusters, paths, partial = false)
	expanded_clusters = []
	all_stats = []
	clusters.each do |id, genes|
		expanded_genes, avg_sh_path = expand_cluster(genes, paths, partial)
		expanded_clusters << [id, expanded_genes]
		all_stats << [id, avg_sh_path]
	end
	return expanded_clusters, all_stats
end

def expand_cluster(genes, paths, partial = false)
	genes = genes.dup
	expanded_genes = []
	connected = true
	path_lengths = []
	while genes.length > 1 && connected
		source = genes.pop
		genes.each do |target|
			pair_data = get_path_data(source, target, paths)
			if !pair_data.nil?
				path = pair_data[6]
				path_lengths << path.length
				expanded_genes.concat(path)
			else
				STDERR.puts "#{source} - #{target} has no path"
				path_lengths << nil
				if partial
					expanded_genes.concat([source, target])
				else # No path between source and target
					connected = false
					break
				end
			end
		end
	end
	expanded_genes.uniq!
	n_genes = expanded_genes.length 
	path_lengths.include?(nil) || n_genes == 0 ? avg_p_len = Float::NAN : avg_p_len = path_lengths.inject(0){|sum, n| sum + n}.fdiv(n_genes)	
	return expanded_genes, avg_p_len
end

def get_network_distances(seed_groups, group_candidates, paths)
	distances_by_group = {}
	group_candidates.each do |id, candidates|
		seeds = seed_groups[id]
		candidates = candidates - seeds
		distances = {}
		candidates.each do |candidate|
			distance = get_average_path_distance(candidate, seeds, paths)
			distances[candidate] = distance
		end
		distances_by_group[id] = distances if !distances.empty?
	end
	return distances_by_group
end

def get_average_path_distance(candidate, seeds, paths)
	distances = []
	seeds.each do |target|
		path_data = get_path_data(candidate, target, paths)
		distances << path_data.first if !path_data.nil?
	end
	return distances.inject(0){|sum, n| sum + n}.fdiv(distances.length)
end

def get_path_data(source, target, paths)
	pair_data = paths.dig(source, target)
	pair_data = paths.dig(target, source) if pair_data.nil?
	return pair_data
end
#################################
##OPT-PARSER
#################################

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: #{__FILE__} [options]"

	options[:input_file] = nil
	opts.on("-i", "--input_file PATH", "HGC aggreated data") do |data|
		options[:input_file] = data
	end

	options[:input_folder] = nil
	opts.on("-f", "--input_folder PATH", "Folder with HGC specific connectome files files") do |data|
		options[:input_folder] = data
	end

	options[:gene_list] = nil
	opts.on("-g", "--gene_list PATH", "File with gene list to select pairs") do |data|
		options[:gene_list] = data
	end

	options[:partial] = false
	opts.on("-p", "--partial", "Allows clusters with incomplete paths") do 
		options[:partial] = true
	end

	options[:simple] = false
	opts.on("-S", "--simple", "Simple data path") do 
		options[:simple] = true
	end

	options[:output_file] = 'output.txt'
	opts.on("-o", "--output_file PATH", "Output combined file") do |data|
		options[:output_file] = data
	end

	options[:stat_file] = nil
	opts.on("-s", "--stat_file PATH", "Output file with clusters statistics") do |data|
		options[:stat_file] = data
	end

	options[:threshold] = nil
	opts.on("-t", "--threshold FLOAT", "p-value threshold") do |data|
		options[:threshold] = data.to_f
	end
end.parse!

#################################
##MAIN
#################################
if !options[:input_folder].nil?
	gene_list = nil
	gene_list = load_tabular(options[:gene_list]).flatten if !options[:gene_list].nil?
	all_data = compact_hgc(options[:input_folder], gene_list)
	write_tabular(all_data, options[:output_file])
elsif !options[:input_file].nil?
	if options[:simple]
		paths, nodes = load_paths_simple(options[:input_file])
	else
		paths, nodes = load_paths(options[:input_file], options[:threshold])
	end
	clusters = load_clusters(options[:gene_list], nodes)
	expanded_clusters, all_stats = expand_clusters(clusters, paths, options[:partial])
	distances_by_cluster = get_network_distances(clusters, expanded_clusters, paths)
	File.open(File.join(File.dirname(options[:output_file]), 'distances.txt'), 'w') do |f|
		distances_by_cluster.each do |cl_id, gene_distances|
			gene_distances = gene_distances.to_a.sort{|d1, d2| d1[1] <=> d2[1]}
			count = 1
			gene_distances.each do |gene, distance|
				f.puts [cl_id, gene, distance, count.fdiv(gene_distances.length)].join("\t") if !distance.nan?
				count += 1
			end
		end
	end
	write_nested_tabular(expanded_clusters, options[:output_file], 1)
	write_tabular(all_stats, options[:stat_file]) if !options[:stat_file].nil?
end
