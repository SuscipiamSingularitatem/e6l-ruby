# e6l-ruby
Take e621 with you, Ruby+MongoDB style.

[![BCH compliance](https://bettercodehub.com/edge/badge/CyberYiff/e6l-ruby?branch=master)](https://bettercodehub.com/)

## Quick start
While it doesn't do much right now, you can use the development version easily:
```
$> git clone https://github.com/CyberYiff/e6l-ruby.git && cd e6l-ruby
$> bundle install   # May take a while if not already installed, requires Bundler (gem install bundler)
$> mv settings.toml.new settings.toml   # Or manually change settings (JSON is also supported)
$> ./test.sh
```
Docs are hosted on [CyberYiff.github.io](https://cyberyiff.github.io/e6l-ruby) (Jekyll reads from `docs/` on the `master` branch). To rebuild the docs, run `yard doc` in the repo dir.
