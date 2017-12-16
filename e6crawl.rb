#!/usr/bin/env ruby

require "curb"
require "json"
require "os"
require "toml"

module E621Crawler
	PRETTY_JSON = {space: " ", object_nl: "\n", array_nl: "\n", indent: "\t"}
	SETTINGS = File.exist?("settings.toml") ? TOML.load_file("settings.toml") : JSON[File.read("settings.json")]
	USER_AGENT = "e6l-ruby/0.1 (by @YoshiRulz on e621; @SuscipiamSingularitatem on GitHub) Curb/#{Curl::CURB_VERSION} (" +
		(OS.posix? ? (OS.mac? ? "macOS; " : "Linux; ") : (OS.doze? ? "Windows; " : "")) +
		"Ruby/#{RUBY_VERSION})"

	class PostData
		attr_reader :raw_hash

		def initialize(h)
			@raw_hash = h
			@tags = h["tags"]
		end
		def PostData.mass_init(a)
			r = []
			a.each do |h| r << PostData.new(h) end
			return r
		end

		def is_sfw?
			@sfw = @raw_hash["rating"] == "s" if @sfw.nil?
			return @sfw
		end

		def debug_tags
			puts JSON.generate(@tags, PRETTY_JSON)
		end
	end

	class Post
		def Post.index(options = {})
			tags = options[:tags].nil? ? [] : (options[:tags].class == String ? [options[:tags]] : options[:tags])

			if options[:metatags].nil?
				metatags = {}
			else
				metatags = options[:metatags]
				options.delete :metatags
			end

			# Defaults in options
			options[:limit] = 100 if options[:limit].nil?
			metatags["rating"] = "s" if options[:tags].nil? # no tags ==> grab latest SFW (from e926)

			# Overwrite options w/ user settings
			unless SETTINGS["username"].nil? || SETTINGS["apikey"].nil?
				options[:login] = SETTINGS["username"]
				options[:password_hash] = SETTINGS["apikey"]
			end
			unless !SETTINGS["ignore_tag_cat"].nil? && SETTINGS["ignore_tag_cat"]
				options[:typed_tags] = true
			end

			# Put tags into options
			domain = "e621.net"
			if metatags[:rating] == "s"
				domain = "e926.net"
				metatags.delete :rating
			end
			metatags.each do |k, v|
				case k
				when :rating
					tags << "rating:#{v}"
				when :order
					tags << "order:#{v}"
				end
			end
			options[:tags] = tags*" "

			# Generate querystring
			query = {}
			options.each do |k, v|
				query[k.to_s] = v
			end

			http = Curl.get("https://#{domain}/post/index.json", query) do |http|
				http.headers["User-Agent"] = USER_AGENT
			end
			return PostData.mass_init JSON[http.body_str]
		end
	end
end
