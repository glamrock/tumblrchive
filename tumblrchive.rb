#!/usr/bin/env ruby1.8

require 'rubygems'
require 'optparse'
require 'hpricot'
require 'open-uri'
require 'rexml/document'
require 'pony'

class Tumblrchiver

	# @param baseurl Front page of the tumblr.
	# @param options Options hash (:full, :output_dir).
	def initialize(baseurl, options)
		@baseurl = baseurl
		@baseurl = "http://" + @baseurl unless @baseurl.include?("http://")
		@baseurl += '/' unless @baseurl[-1] == '/'

		@domain = @baseurl.scan(/\/([^\/]+?)\//)[0][0]

		@options = options
		@odir = options[:output_dir] || @domain
	end

	def start
		system "mkdir #{@odir}"

		offset = 0


		while true
			xml = open(@baseurl + "api/read?start=#{offset}").read
			doc = REXML::Document.new(xml)

			foundone = false
			doc.each_element('//post') do |post|
				path = File.join(@odir, "#{post.attributes['id']}.html")

				if !File.exists?(path) || @options[:full]
					foundone = true



					if @options[:email_alert]
						title = post.get_elements("regular-title")[0].text
						body = post.get_elements("regular-body")[0].text
						

						emh = (@options[:email_header] || "") + "\n\n\n"
						emf = "\n\n\n" + (@options[:email_footer] || "")

						Pony.mail(:to => @options[:email_to],
											:from => @options[:email_from],
											:subject => "New '#{@domain}' post: '#{title}'",
											:html_body => "#{emh}#{body}#{emf}",
											:via => :smtp)
					end

					system "wget -O #{path} #{post.attributes['url']}"
				end
			end

			break unless foundone

			offset += 20
		end
	end
end

if __FILE__ == $0
	options = {}

	optparse = OptionParser.new do |opts|
		opts.banner = "Usage: tumblrchive.rb [options] baseurl [output_dir]"

		opts.on('-f', '--full', "Full archive; overwrite existing files.") do
			options[:full] = true	
		end

		opts.on('-o DIR', '--output-dir DIR', 'Output directory') do |dir|
			options[:output_dir] = dir
		end

		opts.on('-e', '--email-alert', 'Send email alert if new post is detected') do
			options[:email_alert] = true
		end

		opts.on('--email-from FROM', 'On email alert, send from this address') do |from|
			options[:email_from] = from
		end

		opts.on('--email-to TO', 'On email alert, send to this address') do |to|
			options[:email_to] = to
		end

		opts.on('--email-header HEADER', 'A header to be added to the email alert') do |header|
			options[:email_header] = header
		end

		opts.on('--email-footer FOOTER', 'A footer to be added to the email alert') do |footer|
			options[:email_footer] = footer
		end

		opts.on('-h', '--help', "Display this help message") do
			puts opts
			exit
		end

		opts.parse!(ARGV)

		if ARGV.length < 1
			puts opts
			exit
		end
	end

	archiver = Tumblrchiver.new(ARGV[0], options)
	archiver.start
end
