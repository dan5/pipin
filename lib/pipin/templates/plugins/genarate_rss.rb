# -*- encoding: UTF-8 -*-
require 'rss/maker'

module Pipin
  class Builder
    def render_rss(options = {})
      options[:limit] ||= 20
      posts = Post.find(Diary_pattern, :limit => options[:limit])
      rss = generate_rss(posts, options)
      create_distfile('rss', rss)
    end

    def generate_rss(entries, options = {})
      top = config[:base_url].sub(/\/\z/, '')
      RSS::Maker.make("1.0") do |maker|
        entries.each do |entry|
          item = maker.items.new_item
          item.link            = "#{top}/#{entry.label + html_extname}"
          item.description     = entry.rss_description
          item.title           = entry.rss_tile
          item.content_encoded = entry.rss_body
          item.date            = entry.time
        end
        maker.channel.link  = top
        maker.channel.about = options[:about] || "abaout"
        maker.channel.title = options[:title] || config[:title]
        maker.channel.description = options[:description] || config[:description] || 'Please set config[:description] in pipinrc'
      end.to_s
    end
  end

  class Post
    def rss_description(n = 128)
      /^.{0,#{n}}/m.match(to_html.gsub(/(.*<\/h3>)|(<[^>]*>)|(\s+)/mi, '')).to_s + '...'
    end
  
    def rss_tile
       to_html[/<h2>.*<\/h2>/i].to_s.gsub(/<[^>]*>/, '')
    end
  
    def rss_body
      to_html
    end
  
    def time
      Time.parse(date.to_s)
    end
  end
end

if __FILE__ == $0
  $LOAD_PATH.unshift '../lib'
  require 'pipin'
  load './pipinrc'
  setup_environment
  Pipin::Exec.new("rss").build
end
