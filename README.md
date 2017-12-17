# e6l-ruby
Take e621 with you, Ruby+MongoDB style.

[![BCH compliance](https://bettercodehub.com/edge/badge/CyberYiff/e6l-ruby?branch=master)](https://bettercodehub.com/)

## Quick start
While it doesn't do much right now, you can use the development version easily:
```
$> gem install curb os qtbindings toml   # May take a while if not already installed
$> git clone https://github.com/CyberYiff/e6l-ruby.git && cd e6l-ruby
$> mv settings.toml.new settings.toml   # Or manually change settings (JSON is also supported)
$> ./test.sh
```
If you want to generate docs as well:
```
$> gem install yard
$> yard doc
```
