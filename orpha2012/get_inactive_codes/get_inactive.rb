#! /usr/bin/env ruby

require 'optparse'
require 'nokogiri'
require 'nokogiri'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  options[:input] = nil
  opts.on("-i", "--input_file PATH", "Path to input file") do |item|
    options[:input] = item
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!


parsed_info = Nokogiri::XML(File.open(options[:input]))
parsed_info.xpath("//DisorderList//Disorder").each do |item|
	code = item.at('OrphaCode').content
	status = item.at('Totalstatus').content
	puts code if status.include?('Inactive')
end
