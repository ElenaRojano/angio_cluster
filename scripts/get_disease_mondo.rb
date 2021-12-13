#! /usr/bin/env ruby

require 'optparse'
require 'semtools'

##############
## METHODS
##############

def load_file(file, sense)
  codes = []
  File.open(file).each do |line|
    line.chomp!
    line = line.to_sym if sense == :byTerm
    codes << line
  end
  return codes
end

def translate_terms(ontology, codes, output_file, sense)
	File.open(output_file, 'w') do |f|
    codes.each do |code|
      if sense == :byValue
        q_code = code.gsub("ORPHA", "Orphanet")
        mondo_code = ontology.dicts[:diseaseIDs][sense][q_code]
  	    f.puts [code, mondo_code.first].join("\t") unless mondo_code.nil?
      else
        mondo_code = ontology.dicts[:diseaseIDs][sense][code]
        f.puts [code, mondo_code.first].join("\t") unless mondo_code.nil? 
      end
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

  options[:value] = true
  opts.on("-s", "--sense", "If set, dictionaries are set to 'byTerm'") do
    options[:value] = false
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
sense = options[:value] ? :byValue : :byTerm
codes = load_file(options[:input_file], sense)
onto.calc_dictionary(:xref, select_regex: /(#{options[:keyword]})/, store_tag: :diseaseIDs, multiterm: true, substitute_alternatives: false)
translate_terms(onto, codes, options[:output_file], sense)