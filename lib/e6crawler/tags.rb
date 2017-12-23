module E621Crawler
	# Contains the functionality of e621.net/tag/*.
	class Tags
		# Interfaces with {https://e621.net/tag/show.json}.
		# @e926_nsfw May request NSFW material from e926.net, even with safe_only.
		# @return Hash the tag's data
		def Tags.show_id(id)
			E621Crawler.http_get_json(E6lSettings.get.safe_only, "tag/show.json",
				E6lSettings.auth_query({"id" => id}))
		end

		# (see Tags.show_id)
		def Tags.show(id) Tags.show_id id end
	end
end
