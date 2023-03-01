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

#################################
##OPT-PARSER
#################################

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: #{__FILE__} [options]"

	options[:input_file] = nil
	opts.on("-i", "--input_file PATH", "Ranking file") do |data|
		options[:input_file] = data
	end

	options[:reference] = nil
	opts.on("-r", "--reference_file PATH", "Path to reference data") do |data|
		options[:reference] = data
	end

	options[:tops] = [1, 5, 10, 20, 30, 50]
	opts.on("-t", "--tops STRING", "List of tops to be used, comma separated") do |data|
		options[:tops] = data.split(',').map{|i| i.to_i}
	end

	options[:ascending] = false
	opts.on("-a", "--ascending", "Sort ranking in ascending order") do 
		options[:ascending] = true
	end

	options[:output_file] = 'output.txt'
	opts.on("-o", "--output_file PATH", "Output combined file") do |data|
		options[:output_file] = data
	end

	options[:col_id] = 0
	opts.on("-I", "--col_id INTEGER", "Column with record identifier") do |data|
		options[:col_id] = data.to_i
	end

	options[:col_score] = 1
	opts.on("-S", "--col_score INTEGER", "Column with record score") do |data|
		options[:col_score] = data.to_i
	end
end.parse!

#################################
##MAIN
#################################

ranking = load_tabular(options[:input_file])
ranking.select!{|r| r[options[:col_score]] != 'NaN'}
ranking.map!{|r| [r[options[:col_id]], r[options[:col_score]].to_f]}
if options[:ascending]
	ranking.sort!{|i1, i2| i1[1] <=> i2[1]}
else
	ranking.sort!{|i1, i2| i2[1] <=> i1[1]}
end
puts ranking[0..40].inspect
reference = load_tabular(options[:reference]).flatten
max_intersection = (reference & ranking.map{|r| r[0]}).length
puts "ref size: #{reference.length} - intersection: #{max_intersection}"

table = []
top = {} 
options[:tops].each do |n_top|
	ids = []
	while top.length < n_top && !ranking.empty?
		id, val = ranking.shift
		top[id] = val
	end
	intersection_length = (top.keys & reference).length
	ratio = intersection_length.fdiv(reference.length)
	top_ratio = intersection_length.fdiv(n_top)
	intersection_ratio = intersection_length.fdiv(max_intersection)
	table << [n_top, ratio, top_ratio, intersection_ratio]
end

File.open(options[:output_file], 'w') do |f|
	f.puts "top\tratio\ttop_ratio\tintersection_ratio"
	table.each do |row|
		f.puts row.join("\t")
	end
end