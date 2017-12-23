module E621Crawler
	# Contains the functionality of e621.net/wiki/*.
	class Wiki
		# Interfaces with {https://e621.net/wiki/show.json}.
		# @e926_nsfw May request NSFW material from e926.net, even with safe_only.
		# @return Hash the wiki page's data
		def Wiki.show(title)
			E621Crawler.http_get_json("https://e#{E6lSettings.get.safe_only ? "926" : "621"}.net/wiki/show.json",
				E6lSettings.auth_query({"title" => title}))
		end
	end
end