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

	def E621Crawler.http_get_json(use_e926, api_loc, query)
		uri = "e#{use_e926 ? 926 : 621}.net/#{api_loc}"
		if E6lSettings.get.dry_run
			temp = "GET #{uri}"
			query.each do |k, v|
				temp += "&#{k}=#{v}"
			end
			puts temp.sub("&", "?")
			return intern_dryrun_data api_loc
		else
			http = Curl.get("https://#{uri}", query) do |http|
				http.headers["User-Agent"] = USER_AGENT
			end
			return JSON[http.body_str]
		end
	end
	def intern_dryrun_data(api_loc)
		return case api_loc
		when /post\/index.json/
			[intern_dryrun_data("post/show.json")]
		when /post\/show.json/
			{"file_ext" => "png", "tags" => [intern_dryrun_data("post/tags.json")]}
		when /post\/tags.json/
			["e6l:debug"]
		when /(tags|wiki)\/show.json/
			{"id" => 0}
		when /wiki\/index.json/
			[intern_dryrun_data("wiki/show.json")]
		else
			{}
		end
	end

	class PostData
		attr_reader :raw_hash
		attr_reader :ext, :preview_tempfile, :sample_tempfile

		def initialize(h)
			@raw_hash = h
			@tags = h["tags"]
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
