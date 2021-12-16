#! /usr/bin/env ruby

require 'optparse'

#################################
##METHODS
#################################

def generate_disease_genes_hpos(input_file)
	disease_genes = {}
	disease_hpos = {}
	File.open(input_file).each do |line|
		line.chomp!
		gen, hpo, disease = line.split("\t")
		add2hash(disease_genes, disease, gen)
		add2hash(disease_hpos, disease, hpo)
	end
	return disease_genes, disease_hpos
end

def add2hash(hash, key, val)
	query = hash[key]
	if query.nil?
		hash[key] = [val]
	else
		query << val unless query.include?(val)
	end
end

def save_file(output_path, info_hash, sep, tag)
	File.open(output_path, 'w') do |f|
		f.puts "DiseaseID\t#{tag}"
		info_hash.each do |disease, hpo_a|
			hpo = hpo_a.join(sep)
			f.puts "#{disease}\t#{hpo}\n"
		end
	end
end

#################################
##OPT-PARSER
#################################

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: #{__FILE__} [options]"

	options[:input_file] = nil
	opts.on("-i", "--input_file PATH", "Input file with three columns: GeneID, HPOID and disease codes") do |data|
		options[:input_file] = data
	end

	options[:genes_file] = nil
	opts.on("-g", "--genes_file PATH", "Output disease - GeneID file") do |data|
		options[:genes_file] = data
	end

	options[:hpo_file] = nil
	opts.on("-h", "--hpo_file PATH", "Output disease - HPOID file") do |data|
		options[:hpo_file] = data
	end
end.parse!

#################################
##MAIN
#################################

disease_genes, disease_hpos = generate_disease_genes_hpos(options[:input_file])
save_file(options[:genes_file], disease_genes, ',', 'GeneID' ) if !options[:genes_file].nil?
save_file(options[:hpo_file], disease_hpos, '|', 'HPOID') if !options[:hpo_file].nil?