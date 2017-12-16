#!/usr/bin/env ruby

require "json"
require "./e6crawl.rb"

PRETTY_JSON = {space: " ", object_nl: "\n", array_nl: "\n", indent: "\t"}

output = E621Crawler::Post.index(tags: ["yoshi"], limit: 1)
puts JSON.generate output[0]["tags"], PRETTY_JSON
