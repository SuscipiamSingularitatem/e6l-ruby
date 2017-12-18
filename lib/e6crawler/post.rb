module E621Crawler
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
			query = E6lSettings.add_auth({})
			options[:typed_tags] = true unless E6lSettings.get.ignore_tag_cat
			metatags[:rating] = "s" if metatags[:rating].nil? && E6lSettings.get.safe_only

			# Metatags -> tags
			domain = "e621.net"
			if metatags[:rating] == "s"
				domain = "e926.net"
				metatags.delete :rating
			end
			metatags.each do |k, v| tags << "#{k.to_s}:#{v}" end

			# Generate querystring
			options[:tags] = tags*" "
			options.each do |k, v| query[k.to_s] = v end

			return PostData.mass_init E621Crawler.http_get_json("https://#{domain}/post/index.json", query)
		end

		def Post.intern_show_tags(is_show, use_id, id, md5, safe)
			E621Crawler.http_get_json("https://e#{safe ? "926" : "621"}.net/post/#{is_show ? "show" : "tags"}.json",
				E6lSettings.add_auth(use_id ? {"id" => id} : {"md5" => md5}))
		end

		# Interfaces with {https://e621.net/post/show.json}.
		# @return (see Post.show_id)
		def Post.show_md5(md5, safe = false) PostData.new Post.intern_show_tags(true, false, nil, md5, safe) end

		# Interfaces with {https://e621.net/post/show.json}.
		# @return [PostData] the post
		def Post.show_id(id, safe = false) PostData.new Post.intern_show_tags(true, true, id, nil, safe) end

		# (see Post.show_id)
		def Post.show(id, safe = false) Post.show_id(id, safe) end

		# Interfaces with {https://e621.net/post/tags.json}.
		# @return (see Post.tags_id)
		def Post.tags_md5(md5, safe = false) Post.intern_show_tags(false, false, nil, md5, safe) end

		# Interfaces with {https://e621.net/post/tags.json}.
		# @return [Array<String>] the post's tags
		def Post.tags_id(id, safe = false) Post.intern_show_tags(false, true, id, nil, safe) end

		# (see Post.tags_id)
		def Post.tags(id, safe = false) Post.tags_id(id, safe) end
	end
end
