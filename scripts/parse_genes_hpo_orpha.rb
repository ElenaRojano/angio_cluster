#! /usr/bin/env ruby

require 'optparse'

#################################
##METHODS
#################################

def generate_orpha_genes_hpos(input_file)
	orpha_genes = {}
	orpha_hpos = {}
	File.open(input_file).each do |line|
		line.chomp!
		gen, hpo, orpha = line.split("\t")
		query1 = orpha_genes[orpha]
		query2 = orpha_hpos[orpha]
		if query1.nil?
			orpha_genes[orpha] = [gen]
		else
			query1 << gen unless query1.include?(gen)
		end
		if query2.nil?
			orpha_hpos[orpha] = [hpo]
		else
			query2 << hpo unless query2.include?(gen)
		end
	end
	return orpha_genes, orpha_hpos
end


def save_file(output_path, info_hash, sep, tag)
	File.open(output_path, 'w') do |f|
		f.puts "DiseaseID\t#{tag}"
		info_hash.each do |orpha, hpo_a|
			hpo = hpo_a.join(sep)
			f.puts "#{orpha}\t#{hpo}\n"
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
	opts.on("-i", "--input_file PATH", "Input file with three columns: GeneID, HPOID and ORPHA codes") do |data|
		options[:input_file] = data
	end

	options[:genes_file] = 'orpha_genes.txt'
	opts.on("-g", "--genes_file PATH", "Output ORPHA - GeneID file") do |data|
		options[:genes_file] = data
	end

	options[:hpo_file] = 'orpha_hpos.txt'
	opts.on("-h", "--hpo_file PATH", "Output ORPHA - HPOID file") do |data|
		options[:hpo_file] = data
	end
end.parse!

#################################
##MAIN
#################################

orpha_genes, orpha_hpos = generate_orpha_genes_hpos(options[:input_file])
save_file(options[:genes_file], orpha_genes, ',', 'GeneID' )
save_file(options[:hpo_file], orpha_hpos, '|', 'HPOID')