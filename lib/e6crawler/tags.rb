module E621Crawler
	# Contains the functionality of e621.net/tags/*.
	class Tags
		# Interfaces with {https://e621.net/tag/show.json}.
		# @return Hash the tag's data
		def Tags.show_id(id)
			E621Crawler.http_get_json("https://e#{E6lSettings.get.safe_only ? "926" : "621"}.net/tag/show.json",
				E6lSettings.add_auth({"id" => id}))
		end

		# (see Tags.show_id)
		def Tags.show(id) Tags.show_id id end
	end
end
