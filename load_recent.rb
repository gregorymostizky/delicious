#encoding;utf-8
require 'bundler/setup'

require 'set'
require 'open-uri'
require 'json'

require 'feedzirra'
require 'hpricot'


def process_single_bookmark(e)
  # entry id example: @entry_id="http://www.delicious.com/url/db62a351ed098a6d8acc42a620d4cfde#quilombosam"
  entry_id = $1 if e.entry_id =~ /.*url\/(.+)#/

  # load 20 latest tags
  detailed_feed = Feedzirra::Feed.fetch_and_parse("http://feeds.delicious.com/v2/rss/url/#{entry_id}?count=20")
  all_tags = Set.new
  all_tags = all_tags.merge(e.categories)
  detailed_feed.entries.each { |p| all_tags = all_tags.merge(p.categories) }

  # load doc body
  doc = open(e.url) { |f| Hpricot(f) }
  doc.search("script").remove
  doc.search("style").remove
  body = doc.search("body").text.gsub(/\s+/,' ')

  #collect
  print "."
  {:url => e.url, :title =>e.title, :tags => all_tags, :body => body}
rescue
  print "e"
  nil
end

def load_recent(count)
  File.open('test.json','a') do |f|
    feed = Feedzirra::Feed.fetch_and_parse("http://feeds.delicious.com/v2/rss/recent?min=2&count=#{count}")
    feed.entries.each do |e|
      rr = process_single_bookmark(e)
      f.puts rr.to_json if rr
      f.flush
    end
  end
end

load_recent(100)

