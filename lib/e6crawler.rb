require "fileutils"
require "net/http"
require "tempfile"

require "curb"
require "os"

["posts", "tags", "wiki"].each do |f| require_relative "e6crawler#{File::SEPARATOR}#{f}.rb" end
require_relative "settings.rb"

module E621Crawler
	DRYRUN_DATA = {
		"post" => {
			"tags" => ["e6l:debug"]
		},
		"tags" => {
			"show" => {"id" => 0}
		},
		"wiki" => {
			"show" => {"id" => 0}
		}
	}
	DRYRUN_DATA["post"]["show"] = {"file_ext" => "png", "tags" => [DRYRUN_DATA["post"]["tags"]]}
	DRYRUN_DATA["post"]["index"] = [DRYRUN_DATA["post"]["show"]]
	DRYRUN_DATA["post"]["update"] = {"post" => DRYRUN_DATA["post"]["show"], "success" => true}
	DRYRUN_DATA["wiki"]["index"] = [DRYRUN_DATA["wiki"]["show"]]

	PRETTY_JSON = {space: " ", object_nl: "\n", array_nl: "\n", indent: "\t"}
	SFW_MODE = E6lSettings.get.safe_only
	USER_AGENT = "e6l-ruby/0.1 (by @YoshiRulz on e621; @SuscipiamSingularitatem on GitHub) Curb/#{Curl::CURB_VERSION} (" +
		(OS.posix? ? (OS.mac? ? "macOS; " : "Linux; ") : (OS.doze? ? "Windows; " : "")) +
		"Ruby/#{RUBY_VERSION})"

	# Overloaded by E621Crawler.http_*_json().
	def E621Crawler.intern_http(is_get, loc, query)
		uri = "e#{loc[0] ? 926 : 621}.net/#{loc[1]}/#{loc[2]}.json"
		if E6lSettings.get.dry_run
			temp = "#{is_get ? "GET" : "POST"} #{uri}"
			query.each do |k, v| temp += "&#{k}=#{v}" end
			puts temp.sub("&", "?")
			temp = DRYRUN_DATA[loc[1]][loc[2]]
			temp["id"] = query["id"] if loc[1] == "post" && loc[2] == "show" # Pass id for ".../*/show.json"?
			return temp
		else
			uri = "https://#{uri}"
			set_ua = proc {|http| http.headers["User-Agent"] = USER_AGENT}
			return JSON[
					(is_get ? Curl.get(uri, query, &set_ua) : Curl.post(uri, query, &set_ua))
				.body_str]
		end
	end
	def E621Crawler.http_get_json(loc, query) intern_http(true, loc, query) end
	def E621Crawler.http_post_json(loc, post_query) intern_http(false, loc, post_query) end

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
