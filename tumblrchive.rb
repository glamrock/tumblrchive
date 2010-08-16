#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'

class Tumblrchiver
	def initialize(baseurl)
		@baseurl = baseurl
		@baseurl += '/' unless @baseurl[-1] == '/'
		@odir ||= baseurl.scan(/\/([^\/]+?)\//)[0][0]
	end

	def start
		system "mkdir #{@odir}"
		1.upto(1.0/0.0) do |i|
			url = @baseurl + "page/#{i}"		

			path = File.join(@odir, "#{i}")

			system "wget -O #{path} #{url}"

			doc = Hpricot(File.read(path))

			if doc.search('div.post').length == 0
				File.delete(path)
				break
			end
		end
	end
end

if __FILE__ == $0
	if ARGV.length < 1
		puts "Usage: tumblrchive target_url"
		exit
	end

	archiver = Tumblrchiver.new(ARGV[0])
	archiver.start
end
