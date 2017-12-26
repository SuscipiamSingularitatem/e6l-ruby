# e6l-ruby
Take e621 with you, Ruby+MongoDB style.

[![BCH compliance](https://bettercodehub.com/edge/badge/CyberYiff/e6l-ruby?branch=master)](https://bettercodehub.com/)

## Quick start
While it doesn't do much right now, you can use the development version easily:
```
$> git clone https://github.com/CyberYiff/e6l-ruby.git && cd e6l-ruby
$> bundle install   # May take a while if not already installed, requires Bundler (`gem install bundler`)
$> mv settings.toml.new settings.toml   # Or manually change settings (JSON is also supported)
$> ./test.sh
```
Docs are hosted on [CyberYiff.github.io](https://cyberyiff.github.io/e6l-ruby) (Jekyll reads from `docs/` on the `master` branch). To rebuild the docs, run `yard doc` in the repo dir.

## Examples
Download and display the "sample" version (size-limited) of a particular post:
```ruby
E6lQtGUI.single_sample Posts.show_id 546281
```

From one of Genjar's tag projects - download and display posts from a search of >6 tags (works without privileged!) and record which need to be edited:
```ruby
posts = Posts.index(tags: %w{feral -solo -masturbation -human -humanoid -anthro -feral_on_feral}, metatags: {rating: "e"})
explicit = []
posts.each do |post|
	E6lQtGUI.single_sample post
	puts "Was that post feral on feral [Y/N]?"
	explicit << "#{post.raw_hash["id"]}: #{gets.chomp.upcase}"
end
puts explicit*", "
```

## Relevant xkcd
[![xkcd#1629](https://imgs.xkcd.com/comics/tools.png)](https://xkcd.com/1629)
[xkcd#1629: Tools](https://xkcd.com/1629)
