#! /usr/bin/env ruby

require 'optparse'

##############
## METHODS
##############

def load_mondo_file(file)
	#mondo_genes = {MONDO => [geneA, geneB]}
	mondo_genes = {}
	File.open(file).each do |line|
		line.chomp!
		next if line.include?('subject_taxon_label')
		info = line.split("\t")
		next unless info[3] == 'Homo sapiens'
		gene_id = info[1].gsub(' (human)', '')
		next if gene_id.match(/[^A-Z0-9a-z_-]/)
		mondo_id = info[4]
		query = mondo_genes[mondo_id]
		if query.nil?
			mondo_genes[mondo_id] = [gene_id]
		else
			query << gene_id
		end
	end
	return mondo_genes
end

def find_genes(input_file, mondo_genes, output_file)
	orpha_mondo_genes = []
	File.open(input_file).each do |line|
		line.chomp!
		orpha_id, mondo_id = line.split("\t")
		disease_genes = mondo_genes[mondo_id]
		unless disease_genes.nil?
			disease_genes.each do |gene|
				orpha_mondo_genes << [orpha_id, mondo_id, gene]
			end
		end
	end
	File.open(output_file, 'w') do |f|
		orpha_mondo_genes.each do |info|
			f.puts info.join("\t")
		end
	end
end

##############
## OPTPARSE
##############
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

  options[:input_file] = nil
  opts.on("-i", "--input_file PATH", "List ORPHA and MONDO codes") do |item|
    options[:input_file] = item
  end

  options[:mondo_file] = nil
  opts.on("-m", "--mondo_file PATH", "MONDO file to find genes associated with disease") do |item|
    options[:mondo_file] = item
  end

  options[:output_file] = 'output.txt'
  opts.on("-o", "--output_file PATH", "Output ORPHA, MONDO and genes file") do |item|
    options[:output_file] = item
  end

end.parse!

##############
## MAIN
##############

mondo_genes = load_mondo_file(options[:mondo_file])
find_genes(options[:input_file], mondo_genes, options[:output_file])