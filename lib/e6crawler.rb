require "fileutils"
require "net/http"
require "tempfile"

require "curb"
require "os"

["posts", "tags", "wiki"].each do |f| require_relative "e6crawler#{File::SEPARATOR}#{f}.rb" end

module E621Crawler
	PRETTY_JSON = {space: " ", object_nl: "\n", array_nl: "\n", indent: "\t"}
	USER_AGENT = "e6l-ruby/0.1 (by @YoshiRulz on e621; @SuscipiamSingularitatem on GitHub) Curb/#{Curl::CURB_VERSION} (" +
		(OS.posix? ? (OS.mac? ? "macOS; " : "Linux; ") : (OS.doze? ? "Windows; " : "")) +
		"Ruby/#{RUBY_VERSION})"

	def E621Crawler.http_get_json(loc, query)
		uri = "e#{loc[0] ? 926 : 621}.net/#{loc[1]}/#{loc[2]}.json"
		if E6lSettings.get.dry_run
			temp = "GET #{uri}"
			query.each do |k, v|
				temp += "&#{k}=#{v}"
			end
			puts temp.sub("&", "?")
			return intern_dryrun_data(loc[1], loc[2])
		else
			http = Curl.get("https://#{uri}", query) do |http|
				http.headers["User-Agent"] = USER_AGENT
			end
			return JSON[http.body_str]
		end
	end
	def E621Crawler.http_post_json(loc, post_query)
		uri = "e#{loc[0] ? 926 : 621}.net/#{loc[1]}/#{loc[2]}.json"
		if E6lSettings.get.dry_run
			temp = "POST #{uri}"
			post_query.each do |k, v|
				temp += "&#{k}=#{v}"
			end
			puts temp.sub("&", "?")
			return intern_dryrun_data(loc[1], loc[2])
		else
			http = Curl.post("https://#{uri}", post_query) do |http|
				http.headers["User-Agent"] = USER_AGENT
			end
			return JSON[http.body_str]
		end
	end
	def intern_dryrun_data(d, f)
		case d
		when "post"; case f
			when "index"; [intern_dryrun_data("post", "show")]
			when "show"; {"file_ext" => "png", "tags" => [intern_dryrun_data("post", "tags")]}
			when "tags"; ["e6l:debug"]
			when "update"; {"post" => intern_dryrun_data("post", "show"), "success" => true}
			else; {}
			end
		when "tags"; case f
			when "show"; {"id" => 0}
			else; {}
			end
		when "wiki"; case f
			when "index"; [intern_dryrun_data("wiki", "show")]
			when "show"; {"id" => 0}
			else; {}
			end
		else; {}
		end
	end

	class PostData
		attr_reader :raw_hash, :tags
		attr_reader :ext, :preview_tempfile, :sample_tempfile

		def initialize(h)
			@raw_hash = h
			@tags = h["tags"]
			@tags = @tags.split(" ") if @tags.class == String
			@ext = h["file_ext"]
		end
		def PostData.mass_init(a)
			r = []
			a.each do |h| r << PostData.new(h) end
			return r
		end

		# @return [Boolean] true if "rating:s"
		def is_sfw?
			@sfw = @raw_hash["rating"] == "s" if @sfw.nil?
			return @sfw
		end

		def dl_preview
			if @preview_tempfile.nil?
				@preview_tempfile = Tempfile.new(["e6l-", "." + @raw_hash["file_ext"]])
				if E6lSettings.get.dry_run
					FileUtils.touch @preview_tempfile.path
				else
					url = @raw_hash["preview_url"]
					domain = "static1.e#{url.include?("e926.net/") ? "926" : "621"}.net"
					Net::HTTP.start(domain) do |http|
						open(@preview_tempfile.path, "wb") do |file|
							file.write http.get(url.split(domain)[1]).body
						end
					end
				end
			end
		end
		def dl_sample
			if @sample_tempfile.nil?
				@sample_tempfile = Tempfile.new(["e6l-", "." + @raw_hash["file_ext"]])
				if E6lSettings.get.dry_run
					FileUtils.touch @preview_tempfile.path
				else
					url = @raw_hash["sample_url"]
					domain = "static1.e#{url.include?("e926.net/") ? "926" : "621"}.net"
					Net::HTTP.start(domain) do |http|
						open(@sample_tempfile.path, "wb") do |file|
							file.write http.get(url.split(domain)[1]).body
						end
					end
				end
			end
		end

		def debug_tags; puts JSON.generate(@tags, PRETTY_JSON) end
	end
end
