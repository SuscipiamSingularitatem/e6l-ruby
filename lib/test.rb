#!/usr/bin/env ruby

require_relative "e6crawl.rb"

output = E621Crawler::Post.index(tags: "#{["mlp", "rainbow_dash_(mlp)", "twilight_sparkle_(mlp)", "mario_bros", "yoshi", "canine", "feline", "equine", "shark"].sample} -animated", metatags: {order: ["favcount", "score"].sample}, limit: 1)
E621Crawler::QtGUI.debug_thumb(output[0])
