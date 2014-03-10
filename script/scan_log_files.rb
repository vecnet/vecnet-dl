#!/usr/bin/env ruby -I../lib

# This is an extremely simple command line interface to the vecnet log
# parsing class. See doc/usage-information.md

require 'log_parser'
require 'vecnet_usage'

a = VecnetUsage.new
ARGV.each do |fname|
  printf "Scanning #{fname}\n"
  a.scan_file(fname)
end
a.output_results

