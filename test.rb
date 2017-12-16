#!/usr/bin/env ruby

require "./e6crawl.rb"

output = E621Crawler::Post.index(tags: ["yoshi"], limit: 1)
puts output[0].raw_hash
