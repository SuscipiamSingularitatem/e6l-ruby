#!/usr/bin/env ruby

["e6crawler", "qtgui", "settings"].each do |f| require_relative "#{f}.rb" end
include E621Crawler

output = Posts.index(tags: "#{["mlp", "rainbow_dash_(mlp)", "twilight_sparkle_(mlp)", "mario_bros", "yoshi", "canine", "feline", "equine", "shark"].sample} -animated", metatags: {order: ["favcount", "score"].sample}, limit: 1)
E6lQtGUI.single_preview(output[0])
