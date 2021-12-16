#! /usr/bin/env ruby

require 'optparse'

###############################################################
## METHODS
###############################################################
def process_attrib(id, xrefs, subset)
	rec = []
	if xrefs.empty? && subset =~ /^ordo_disease/
		prefix, pairs_string = subset.split(' ', 2)
		if !pairs_string.nil?
			sources = pairs_string.gsub('{','').gsub('}','').split(',')
			sources.each do |source_str|
				prefix, source = source_str.split('=')
				source.gsub!('"','')
				rec << [id, source]
			end
		end
	end
	return rec
end

###############################################################
## OPTPARSE
###############################################################
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

  options[:input] = nil
  opts.on("-i", "--input_file PATH", "Path to input file") do |item|
    options[:input] = item
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

terms = false
id = nil
xref = []
subset = nil
records = []
File.open(options[:input]).each do |line|
	line.chomp!
	next if line.empty?
	if line == '[Term]'
		terms = true
		if !id.nil?
			rec = process_attrib(id, xref, subset)
			records.concat(rec) if !rec.empty?
		end
		id, subset = nil
		xref = []
	elsif line == '[Typedef]'
		break
	elsif terms
		attrib, value = line.split(' ', 2)
		value.strip!
		if attrib == 'id:'
			id = value
		elsif attrib == 'xref:'
			xref << value if value =~ /^Orphanet:/
		elsif attrib == 'subset:'
			subset = value
		end
	end
end
records.each do |rec|
	puts rec.join("\t")
end