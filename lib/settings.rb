require "json"
require "toml"

module E6lSettings
	class E6lSettingsHandler
		attr_reader :apikey, :ignore_tag_cat, :login_given, :safe_only, :username

		def initialize(h)
			@apikey = h["apikey"]
			@username = h["username"]
			@login_given = !(@username.nil? || @apikey.nil?) if @login_given.nil?

			@ignore_tag_cat = h["ignore_tag_cat"]
			@ignore_tag_cat = false if @ignore_tag_cat.nil?

			@safe_only = h["safe_only"]
			@safe_only = false if @safe_only.nil?
		end
	end

	@@settings_handler = nil
	def E6lSettings.reload; @@settings_handler = E6lSettingsHandler.new(File.exist?("settings.toml") ? TOML.load_file("settings.toml") : JSON[File.read("settings.json")]) end
	reload

	def E6lSettings.get; @@settings_handler end

	def E6lSettings.add_auth(query)
		if E6lSettings.get.login_given
			query["login"] = E6lSettings.get.username
			query["password_hash"] = E6lSettings.get.apikey
		end
		return query
	end
end
