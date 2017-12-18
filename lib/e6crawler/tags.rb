module E621Crawler
	class Tags
		# Interfaces with {https://e621.net/tag/show.json}.
		# @return Hash the tag's data
		def Tags.show_id id
			query = {"id" => id}

			# Read user settings
			if E6lSettings.get.login_given
				query["login"] = E6lSettings.get.username
				query["password_hash"] = E6lSettings.get.apikey
			end

			return E621Crawler.http_get_json("https://e#{E6lSettings.get.safe_only ? "926" : "621"}.net/tag/show.json", query)
		end

		# Interfaces with {https://e621.net/tag/show.json}.
		# @return Hash the tag's data
		def Tags.show(id) return Tags.show_id id end
	end
end
