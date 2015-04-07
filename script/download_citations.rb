#!/usr/bin/env ruby

# Download Content from the Digital Library
#
# Usage:
#   ./download_citations.rb noid1 noid2 files/noid3
#
# Assumes noids by themselves are to citations, and noids prefixed by
# "files/" refer to generic files. Downloads the records metadata as
# the file "noid.xml", and for generic files the content as "noid.pdf".
# For citations, the attached files are downloaded as "noid_1.pdf",
# "noid_2.pdf", etc. All files are put in the current directory.
#
# Set the environment variable PUBTKT to a valid pubtkt to access restricted
# content.
#
# TODO: support API keys?

require 'cgi'
require 'nokogiri'
require 'rest-client'

HOST = "https://dl.vecnet.org"

def get_item_xml(path, noid, cookie)
  doc = RestClient.get(path, cookies: cookie)
  File.open("#{noid}.xml", "w") do |f|
    f.write(doc.body)
  end
  Nokogiri::XML(doc.body)
rescue => e
  puts e
end

def get_file(noid, fname, cookie)
  puts "    #{noid}..."
  doc = RestClient.get("#{HOST}/downloads/#{noid}", cookies: cookie)
  File.open(fname, "wb") do |f|
    f.write(doc.body)
  end
rescue => e
  puts e
end

def download_one_generic_file(noid, cookie)
  xml = get_item_xml("#{HOST}/files/#{noid}.xml", noid, cookie)
  get_file(noid, "#{noid}.pdf", cookie) unless xml.nil?
end

def download_one_citation(noid, cookie)
  xml = get_item_xml("#{HOST}/citations/#{noid}.xml", noid, cookie)
  return if xml.nil?
  xml.xpath("//vn:child_records", 'vn' => 'https://dl.vecnet.org/')
     .each_with_index do |child, i|
    child_noid = child.text
    get_file(child_noid, "#{noid}_#{i}.pdf", cookie)
  end
end

pubtkt = ENV['PUBTKT']
cookie = {}
if pubtkt
  cookie['auth_pubtkt'] = CGI.escape(pubtkt)
  puts cookie['auth_pubtkt']
else
  puts "no PUBTKT found"
end

ARGV.each do |noid|
  if noid.start_with?("files/")
    noid = noid[6..-1]
    puts "Downloading GenericFile #{noid}"
    download_one_generic_file(noid, cookie)
  else
    puts "Downloading citation #{noid}"
    download_one_citation(noid, cookie)
  end
end
