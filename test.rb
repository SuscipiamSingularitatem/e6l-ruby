#!/usr/bin/env ruby

require_relative "e6crawl.rb"

output = E621Crawler::Post.index(tags: "rainbow_dash_(mlp) -animated", metatags: {rating: "s", order: "favcount"}, limit: 1)
E621Crawler::QtGUI.debug_thumb(output[0])
