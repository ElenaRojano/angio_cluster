#! /usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:input] = nil
  opts.on("-i", "--input_file PATH", "Path to input file") do |item|
    options[:input] = item
  end

  options[:col_index] = nil
  opts.on("-x", "--column_index INTEGER", "Column index (0 based) to use as reference") do |item|
    options[:col_index] = item.to_i
  end

  options[:col_aggregate] = nil
  opts.on("-a", "--column_aggregate INTEGER", "Column index (0 based) to extract data and join for each id in column index") do |item|
    options[:col_aggregate] = item.to_i
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!


agg_data = {}
if options[:input] == '-'
	input = STDIN
else
	input = File.open(options[:input])
end
input.each do |line|
	fields = line.chomp.split("\t")
	key = fields[options[:col_index]]
	val = fields[options[:col_aggregate]]
	query = agg_data[key]
	if query.nil?
		agg_data[key] = [val]
	else
		query << val
	end
end

agg_data.each do |key, values|
	STDOUT.puts "#{key}\t#{values.join(',')}"
end
