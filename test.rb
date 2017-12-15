require "curb"
require "json"

settings = JSON[File.read("settings.json")]

query = {
	"limit" => 1,
	"tags" => "yoshi"
}

unless settings["username"].nil? || settings["apikey"].nil?
	query["login"] = settings["username"]
	query["password_hash"] = settings["apikey"]
end
if settings["ignore_tag_cat"].nil? || !settings["ignore_tag_cat"]
	query["typed_tags"] = true
end

http = Curl.get("https://e621.net/post/index.json", query) do |http|
	http.headers["User-Agent"] = "e6l-ruby/0.1 (by @YoshiRulz on e621)"
end
output = JSON[http.body_str]

puts output.length
puts output[0]["tags"]
