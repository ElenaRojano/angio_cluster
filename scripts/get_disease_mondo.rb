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

def load_supp_dict(file, sense)
  dict = {}
  File.open(file).each do |line|
    m, c = line.chomp.split("\t")
    if sense == :byTerm
      load_hash(dict, m.to_sym, c)
    else
      load_hash(dict, c, m)
    end
  end
  return dict
end

def load_hash(hash_to_fill, key, val)
  query = hash_to_fill[key]
  if query.nil?
    hash_to_fill[key] = [val]
  else
    query << val
  end
end

def translate_terms(ontology, codes, sense, supp_dict)
  recs = []
  codes.each do |code|
    if sense == :byValue
      q_code = code.gsub("ORPHA", "Orphanet")
      mondo_code = ontology.dicts[:diseaseIDs][sense][q_code]
      unless mondo_code.nil?
        mondo_code.each do |mc|
          recs << [code, mc] 
        end
      end
    else
      mondo_code = ontology.dicts[:diseaseIDs][sense][code]
      mondo_code = supp_dict[code] if mondo_code.nil? && !supp_dict.nil?
      unless mondo_code.nil?
        mondo_code.each do |mc|
          recs << [code, mc] 
        end
      end
    end
	end
  return recs.uniq
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

  options[:supp_dict] = nil
  opts.on("-S", "--supp_dict PATH", "Additional list to perform translations") do |item|
    options[:supp_dict] = item
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
supp_dict = nil
supp_dict = load_supp_dict(options[:supp_dict], sense) if !options[:supp_dict].nil?
codes = load_file(options[:input_file], sense)
onto.calc_dictionary(:xref, select_regex: /(#{options[:keyword]})/, store_tag: :diseaseIDs, multiterm: true, substitute_alternatives: false)
recs = translate_terms(onto, codes, sense, supp_dict)
File.open(options[:output_file], 'w') do |f|
  recs.each do |rec|
   f.puts rec.join("\t") 
  end
end
