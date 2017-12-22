require "net/http"
require "tempfile"

require "curb"
require "os"

["post", "tags"].each do |f| require_relative "e6crawler#{File::SEPARATOR}#{f}.rb" end

module E621Crawler
	PRETTY_JSON = {space: " ", object_nl: "\n", array_nl: "\n", indent: "\t"}
	USER_AGENT = "e6l-ruby/0.1 (by @YoshiRulz on e621; @SuscipiamSingularitatem on GitHub) Curb/#{Curl::CURB_VERSION} (" +
		(OS.posix? ? (OS.mac? ? "macOS; " : "Linux; ") : (OS.doze? ? "Windows; " : "")) +
		"Ruby/#{RUBY_VERSION})"

	def E621Crawler.http_get_json(uri, query)
		http = Curl.get(uri, query) do |http|
			http.headers["User-Agent"] = USER_AGENT
		end
		return JSON[http.body_str]
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
				url = @raw_hash["preview_url"]
				domain = "static1.e#{url.include?("e926.net/") ? "926" : "621"}.net"
				@preview_tempfile = Tempfile.new(["e6l-", "." + @raw_hash["file_ext"]])
				Net::HTTP.start(domain) do |http|
					open(@preview_tempfile.path, "wb") do |file|
						file.write http.get(url.split(domain)[1]).body
					end
				end
			end
		end
		def dl_sample
			if @sample_tempfile.nil?
				url = @raw_hash["sample_url"]
				domain = "static1.e#{url.include?("e926.net/") ? "926" : "621"}.net"
				@sample_tempfile = Tempfile.new(["e6l-", "." + @raw_hash["file_ext"]])
				Net::HTTP.start(domain) do |http|
					open(@sample_tempfile.path, "wb") do |file|
						file.write http.get(url.split(domain)[1]).body
					end
				end
			end
		end

		def debug_tags; puts JSON.generate(@tags, PRETTY_JSON) end
	end
end
