require "json"
require "toml"

module E6lSettings
	class E6lSettingsHandler
		attr_reader :apikey, :dry_run, :ignore_tag_cat, :login_given, :safe_only, :username

		def initialize(h)
			intern_init(h["dry_run"], h["ignore_tag_cat"], h["safe_only"])
			@apikey = h["apikey"]
			@username = h["username"]
			@login_given = !(@username.nil? || @apikey.nil?) if @login_given.nil?
		end
		def intern_init(dry_run = false, ignore_tag_cat = false, safe_only = false)
			@dry_run = dry_run
			@ignore_tag_cat = ignore_tag_cat
			@safe_only = safe_only
		end
	end

	@@settings_handler = nil
	def E6lSettings.reload; @@settings_handler = E6lSettingsHandler.new(File.exist?("settings.toml") ? TOML.load_file("settings.toml") : JSON[File.read("settings.json")]) end
	reload

	def E6lSettings.get; @@settings_handler end

	def E6lSettings.auth_query(query = {})
		if E6lSettings.get.login_given
			query["login"] = E6lSettings.get.username
			query["password_hash"] = E6lSettings.get.apikey
		end
		return query
	end
	def E6lSettings.auth_post(post_query = {})
		if E6lSettings.get.login_given
			post_query[:login] = E6lSettings.get.username
			post_query[:password_hash] = E6lSettings.get.apikey
		end
		return post_query
	end
end
