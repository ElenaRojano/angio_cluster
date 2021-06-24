#! /usr/bin/env ruby

require 'optparse'

#################################
##METHODS
#################################

def load_dictionary(input_file)
	dictionary = {}
	File.open(input_file).each do |line|
		line.chomp!
		next if line.include?('NCBI')
		ncbi, genename, string = line.split("\t")
		query = dictionary[string]
		if query.nil?
			dictionary[string] = genename
		else
			query << genename
		end
	end
	return dictionary
end

def translate_file(file2translate, dictionary)
	translations = []
	untranslated_prots = []
	File.open(file2translate).each do |line|
		line.chomp!
		if !line.include?('protein1')
			info = line.split(" ")
			comb_score = info.last
			geneID1 = dictionary[info.first]
			geneID2 = dictionary[info[1]]
			if geneID1.nil?
				untranslated_prots << info.first
			elsif geneID2.nil?
				untranslated_prots << info[1]
			else
				translations << [geneID1, geneID2, comb_score]
			end
		else
			header = line.split("\t")
		end
	end
	return translations, untranslated_prots.uniq
end

#################################
##OPT-PARSER
#################################

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: #{__FILE__} [options]"
	
	options[:dictionary_file] = nil
	opts.on("-d", "--dictionary_file PATH", "Input file with dictionary of terms") do |data|
		options[:dictionary_file] = data
	end

	options[:input_file] = nil
	opts.on("-i", "--input_file PATH", "Input file to translate") do |data|
		options[:input_file] = data
	end

	options[:untranslated_file] = 'untranslated_prots.txt'
	opts.on("-n", "--untranslated_file PATH", "Output file with untranslated proteins") do |data|
		options[:untranslated_file] = data
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

dictionary = load_dictionary(options[:dictionary_file])
translated_info, untranslated_prots = translate_file(options[:input_file], dictionary)

File.open(options[:output_file], 'w') do |f|
	f.puts "protein1\tprotein2\tcombined_score"
	translated_info.each do |info|
		f.puts info.join("\t")
	end
end

File.open(options[:untranslated_file], 'w') do |f|
	untranslated_prots.each do |protID| 
		f.puts protID
	end	
end