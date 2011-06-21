require 'pipin/version'
require 'haml'
require 'pathname'

include Haml::Helpers
alias h html_escape

module Pipin
  def self.command(cmd)
    __send__ "command_#{cmd}", *ARGV
  end

  def self.command_new(dir)
    # todo: ./new_tamplate をコピーしたほうがいいか
    #[
    #  [:mkdir, dir],
    #  [:create, dir + '/pipinrc'],
    #]
    puts "    create #{dir}"
    Dir.mkdir dir
    Dir.chdir(dir) {
      puts "    create #{dir}/pipinrc"
      File.open('pipinrc', 'w') {}
    }
  end

  def self.command_build(dir = '.')
    load dir + '/pipinrc'
    build = Builder.new('public')
    build.render_posts
    build.render_list('index', '20*', :limit => 3)
  end

  class Builder
    def initialize(dstdir)
      @dstdir = dstdir
    end

    def render_posts
      Post.find('20*').each do |post|
        write_html post.label, render_with_layout(:post, binding)
      end
    end

    def render_list(name, pattern, options = {})
      posts = Post.find(pattern, options)
      write_html name, render_with_layout(:list, binding)
    end

    def write_html(label, html)
      p label
      File.open(File.join(@dstdir, "#{label}.html"), 'w') {|f| f.write html }
    end

    def render_with_layout(template, b = binding)
      render(:layout) { render(template, b) }
    end

    def render(template, b = binding)
      haml = File.read("../views/#{template}.haml")
      Haml::Engine.new(haml).render(b)
    end
  end

  class Post
    @@entries_dir = 'data_sample'
    def self.find(pattern, options = {})
      pattern.gsub!(/[^\d\w_*]/, '') # DON'T DELETE!!!
      files = Dir.chdir(@@entries_dir) { Dir.glob(pattern) }.sort.reverse
      files = files[0, options[:limit]] if options[:limit]
      files.map {|e| Post.new(e) }
    end

    attr_reader :filename, :header, :body
    def initialize(filename)
      @filename = Pathname.new(filename)
      @header, @body = Dir.chdir(@@entries_dir) { @filename.read }.split(/^__$/, 2)
      @header, @body = nil, @header unless @body
    end

    def label
      filename.basename('.*')
    end

    def to_html
      body
    end
  end
end
