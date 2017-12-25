module E621Crawler
	# Contains the functionality of e621.net/post/*.
	class Posts
		# Interfaces with {https://e621.net/post/index.json}.
		# @return [Array<PostData>] one or more posts
		def Posts.index(options = {})
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
			query = E6lSettings.auth_query({})
			options[:typed_tags] = true unless E6lSettings.get.ignore_tag_cat
			metatags[:rating] = "s" if metatags[:rating].nil? && E6lSettings.get.safe_only

			# Metatags -> tags
			use_e926 = false
			if metatags[:rating] == "s"
				use_e926 = true
				metatags.delete :rating
			end
			metatags.each do |k, v| tags << "#{k.to_s}:#{v}" end

			# Generate querystring
			options[:tags] = tags*" "
			options.each do |k, v| query[k.to_s] = v end

			return PostData.mass_init E621Crawler.http_get_json(use_e926, "post/index.json", query)
		end

		# Overloaded by Post.show*() and Post.tags*().
		def Posts.intern_show_tags(is_show, use_id, id, md5, safe)
			E621Crawler.http_get_json(safe, "post/#{is_show ? "show" : "tags"}.json",
				E6lSettings.auth_query(use_id ? {"id" => id} : {"md5" => md5}))
		end

		# Interfaces with {https://e621.net/post/show.json}.
		# @return (see Post.show_id)
		def Posts.show_md5(md5, safe = false) PostData.new Posts.intern_show_tags(true, false, nil, md5, safe) end

		# Interfaces with {https://e621.net/post/show.json}.
		# @return [PostData] the post
		def Posts.show_id(id, safe = false) PostData.new Posts.intern_show_tags(true, true, id, nil, safe) end

		# (see Post.show_id)
		def Posts.show(id, safe = false) Posts.show_id(id, safe) end

		# Interfaces with {https://e621.net/post/tags.json}.
		# @return (see Post.tags_id)
		def Posts.tags_md5(md5, safe = false) Posts.intern_show_tags(false, false, nil, md5, safe) end

		# Interfaces with {https://e621.net/post/tags.json}.
		# @return [Array<String>] the post's tags
		def Posts.tags_id(id, safe = false) Posts.intern_show_tags(false, true, id, nil, safe) end

		# (see Post.tags_id)
		def Posts.tags(id, safe = false) Posts.tags_id(id, safe) end

		# Overloaded by Posts.update_tags()
		def Posts.intern_update_tags(id, old_tags, tags, reason)
			post_query = E6lSettings.auth_post({id: id, tags: tags, old_tags: old_tags})
			post_query[:reason] = reason unless reason.nil?
			E621Crawler.http_post_json(E6lSettings.get.safe_only, "post/update.json", post_query)
		end

		# Interfaces with {https://e621.net/post/update.json}.
		def Posts.update_tags(options)
			raise StandardError.new("OOPS") if options[:add].nil? && options[:remove].nil?
			tags = options[:post].tags.dup
			if options[:add].nil?
				tags.keep_if do |t| !options[:remove].include? t end
			else
				options[:add].each do |t| tags << t end
			end
			Posts.intern_update_tags(options[:post].raw_hash["id"], options[:post].tags*" ", tags*" ", options[:reason])
		end
	end
end
