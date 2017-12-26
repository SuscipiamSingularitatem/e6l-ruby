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
			query = E6lSettings.auth_query
			options[:typed_tags] = true unless E6lSettings.get.ignore_tag_cat
			metatags[:rating] = "s" if metatags[:rating].nil? && SFW_MODE

			# Metatags -> tags
			use_e926 = false
			if metatags[:rating] == "s"
				use_e926 = true
				metatags.delete :rating
			end
			metatags.each do |k, v| tags << "#{k.to_s}:#{v}" end

			# Generate querystring
			offline_tags = nil
			max_tags = (use_e926 ? 5 : 6) - metatags.length # check settings when user types are implemented
			raise StandardError if max_tags < 1
			if tags.length > max_tags # e926 counts as using the "rating:s" tag
				offline_tags = tags
				temp = {} # {tag => count} pairs
				tags.each do |t| temp[t] = Tags.index_exact(t[0] == "-" || t[0] == "~" ? t[1..t.length] : t)["id"] end
				tags = []
				temp.sort_by(&:last).take(6).each do |a| tags << a[0] end # just the names of the 6 tags w/ highest count
				offline_tags -= tags
			end
			options[:tags] = tags*" "
			options.each do |k, v| query[k.to_s] = v end

			posts = PostData.mass_init E621Crawler.http_get_json([use_e926, "post", "index"], query)
			return posts if offline_tags.nil?
			offline_or = offline_tags.select do |t| t[0] == "~" end
			offline_minus = offline_tags.select do |t| t[0] == "-" end
			offline_tags -= offline_or
			offline_tags -= offline_minus
			posts.keep_if do |p| p.flat_tags.any? do |t| offline_or.include?(t) end end if offline_or.length > 0 # are these length checks required?
			posts.keep_if do |p| p.flat_tags.all? do |t| offline_tags.include?(t) end end if offline_tags.length > 0
			posts.keep_if do |p| (p.flat_tags & offline_minus).length == 0 end if offline_minus.length > 0
			return posts
		end

		# Overloaded by Posts.show*() and Posts.tags*().
		def Posts.intern_show_tags(is_show, use_id, id, md5, safe)
			E621Crawler.http_get_json([safe, "post", "#{is_show ? "show" : "tags"}"],
				E6lSettings.auth_query(use_id ? {"id" => id} : {"md5" => md5}))
		end

		# Interfaces with {https://e621.net/post/show.json}.
		# @return (see Posts.show_id)
		def Posts.show_md5(md5, safe = SFW_MODE) PostData.new Posts.intern_show_tags(true, false, nil, md5, safe) end

		# Interfaces with {https://e621.net/post/show.json}.
		# @return [PostData] the post
		def Posts.show_id(id, safe = SFW_MODE) PostData.new Posts.intern_show_tags(true, true, id, nil, safe) end

		# (see Posts.show_id)
		def Posts.show(id, safe = SFW_MODE) Posts.show_id(id, safe) end

		# Interfaces with {https://e621.net/post/tags.json}.
		# @return (see Posts.tags_id)
		def Posts.tags_md5(md5, safe = SFW_MODE) Posts.intern_show_tags(false, false, nil, md5, safe) end

		# Interfaces with {https://e621.net/post/tags.json}.
		# @return [Array<String>] the post's tags
		def Posts.tags_id(id, safe = SFW_MODE) Posts.intern_show_tags(false, true, id, nil, safe) end

		# (see Posts.tags_id)
		def Posts.tags(id, safe = SFW_MODE) Posts.tags_id(id, safe) end

		def Posts.intern_update_tags(id, old_tags, tags, reason)
		end

		# Interfaces with {https://e621.net/post/update.json}.
		# @global_rw Really will change the post's tags on e6. Will not ask for confirmation.
		def Posts.update_tags(options)
			raise StandardError.new("OOPS") if options[:add].nil? && options[:remove].nil?
			tags = options[:post].tags.dup
			if options[:add].nil?
				tags.keep_if do |t| !options[:remove].include? t end
			else
				options[:add].each do |t| tags << t end
			end
			post_query = E6lSettings.auth_post({"id" => options[:post].raw_hash["id"], "tags" => tags*" ", "old_tags" => options[:post].tags*" "})
			post_query[:reason] = options[:reason] unless options[:reason].nil?
			E621Crawler.http_post_json([SFW_MODE, "post", "update"], post_query)
		end
	end
end
