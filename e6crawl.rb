require "net/http"
require "tempfile"

require "curb"
require "json"
require "os"
require "toml"

require "Qt"

require_relative "settings.rb"

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
		attr_reader :ext, :raw_hash, :sample_tempfile

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

		# @return [Boolean] @sfw (true for "rating:s")
		def is_sfw?
			@sfw = @raw_hash["rating"] == "s" if @sfw.nil?
			return @sfw
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

		def debug_tags
			puts JSON.generate(@tags, PRETTY_JSON)
		end
	end

	class Post
		# Interfaces with {https://e621.net/post/index.json}.
		# @return [Array<PostData>] one or more posts
		def Post.index(options = {})
			if options[:tags].nil?
				tags = []
			else
				tags = options[:tags]
				tags = [tags.to_s] if tags.class != Array
			end
			if options[:metatags].nil?
				metatags = {}
			else
				metatags = options[:metatags]
				options.delete :metatags
			end

			# Defaults in options
			options[:limit] = 100 if options[:limit].nil?
			metatags[:rating] = "s" if options[:tags].nil? && options[:metatags].nil? # no tags ==> grab latest SFW (from e926)

			# Overwrite options w/ user settings
			if E6lSettings.get.login_given
				options[:login] = E6lSettings.get.username
				options[:password_hash] = E6lSettings.get.apikey
			end
			unless E6lSettings.get.ignore_tag_cat
				options[:typed_tags] = true
			end
			if metatags[:rating].nil? && E6lSettings.get.safe_only
				metatags[:rating] = "s"
			end

			# Metatags -> tags
			domain = "e621.net"
			if metatags[:rating] == "s"
				domain = "e926.net"
				metatags.delete :rating
			end
			metatags.each do |k, v| tags << "#{k.to_s}:#{v}" end

			# Generate querystring
			options[:tags] = tags*" "
			query = {}
			options.each do |k, v| query[k.to_s] = v end

			return PostData.mass_init E621Crawler.http_get_json("https://#{domain}/post/index.json", query)
		end
	end

	class QtGUI
		class ImageDisplayWindow < Qt::MainWindow
			def initialize(image_path, window_title, width, height)
				super(nil)
				image_label = Qt::Label.new
				image_label.backgroundRole = Qt::Palette::Base
				image_label.setSizePolicy(Qt::SizePolicy::Ignored, Qt::SizePolicy::Ignored)
				image_label.scaledContents = true
				setCentralWidget image_label
				setWindowTitle window_title
				image_label.pixmap = Qt::Pixmap.fromImage Qt::Image.new(image_path)
				image_label.adjustSize
				resize(width, height)
			end
		end
		def QtGUI.debug_thumb(post)
			case post.ext
			when "gif", "jpg", "png"
				post.dl_sample
				path = post.sample_tempfile.path
				width = post.raw_hash["sample_width"]
				height = post.raw_hash["sample_height"]
			when "swf", "webm"
				path = "#{post.ext == "swf" ? "download" : "webm"}-preview.png"
				width = 150
				height = 150
			end
			qt_app = Qt::Application.new(ARGV)
			thumb_window = ImageDisplayWindow.new(path, "e6##{post.raw_hash["id"]} (.#{post.ext})", width, height)
			thumb_window.show
			qt_app.exec
		end
	end
end
