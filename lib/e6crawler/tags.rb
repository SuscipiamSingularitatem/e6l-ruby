module E621Crawler
	class Tags
		# Interfaces with {https://e621.net/tag/show.json}.
		# @return Hash the tag's data
		def Tags.show_id id
			return E621Crawler.http_get_json(
					"https://e#{E6lSettings.get.safe_only ? "926" : "621"}.net/tag/show.json",
					E6lSettings.add_auth({"id" => id})
				)
		end

		# Interfaces with {https://e621.net/tag/show.json}.
		# @return Hash the tag's data
		def Tags.show(id) return Tags.show_id id end
	end
end
