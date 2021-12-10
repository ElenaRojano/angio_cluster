#! /usr/bin/env ruby

require 'optparse'
require 'semtools'

##############
## METHODS
##############

def load_file(file)
  codes = []
  File.open(file).each do |line|
    line.chomp!
    codes << line
  end
  return codes
end

def translate_terms(ontology, codes, output_file)
	File.open(output_file, 'w') do |f|
    codes.each do |code| 
      mondo_code = ontology.dicts[:diseaseIDs][:byValue][code.gsub("ORPHA", "Orphanet")]
  	  f.puts [code, mondo_code.first].join("\t") unless mondo_code.nil?
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
  opts.on("-i", "--input_file PATH", "List of terms to be translated") do |item|
    options[:input_file] = item
  end

  options[:ontology_file] = nil
  opts.on("-f", "--ontology_file PATH", "Ontology file used to get the translated terms") do |item|
    options[:ontology_file] = item
  end

  options[:keyword] = nil
  opts.on("-k", "--keyword STRING", "Regex used to locate xref terms in the ontology file") do |item|
    options[:keyword] = item
  end		

  options[:output_file] = 'output.txt'
  opts.on("-o", "--output_file PATH", "Output file") do |item|
    options[:output_file] = item
  end

end.parse!

##############
## MAIN
##############
onto = Ontology.new(file: options[:ontology_file], load_file: true)
codes = load_file(options[:input_file])
onto.calc_dictionary(:xref, select_regex: /(#{options[:keyword]})/, store_tag: :diseaseIDs, multiterm: true, substitute_alternatives: false)
translate_terms(onto, codes, options[:output_file])