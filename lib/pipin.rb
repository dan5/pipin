require 'pipin/version'
require 'haml'
require 'fileutils'

# todo: move in Pipin
def rootdir() File.join(File.dirname(File.expand_path(__FILE__)), 'pipin') end
def html_extname() config[:html_extname] or '.html' end

module Pipin
  Diary_pattern = '[0-9]' * 8 + '*'
  Post_pattern = '[0-9a-zA-Z]*'

  class Exec
    def initialize(*args)
      @args = args
    end

    def create_from_template
      dir = @args.first
      File.exist?(dir) && raise("File exists - #{dir}")
      FileUtils.cp_r File.join(rootdir ,'templates'), dir
      puts Dir.glob(File.join(dir, '**/*')).map {|e| '  create ' + e }
    end

    def build
      page_name, *opts = @args
      Builder.new('public').__send__('render_' + page_name, *opts)
    end
  end

  class Builder
    def initialize(dist_dir)
      @dist_dir = dist_dir
      load './pipinrc'
      setup_environment
    end

    def render_sitemap
      posts = Post.find(Post_pattern)
      write_html 'sitemap', render_with_layout(:sitemap, binding)
    end

    def render_archives
      years = Post.year_months
      write_html 'archives', render_with_layout(:archives, binding)
    end

    #def render_months
    #  years = Post.year_months
    #  years.each do |year, months|
    #    months.each do |month|
    #      render_month(year, month)
    #    end
    #  end
    #end

    def render_month(year, month)
      name = year + month
      render_list(name, name + '*')
    end

    #def render_posts
    #  Post.find(Post_pattern).each do |post|
    #    write_html post.label, render_with_layout(:post, binding)
    #  end
    #end

    def render_post(label)
      post = Post.find(label).first
      write_html label, render_with_layout(:post, binding)
    end

    def render_index
      render_list('index', Diary_pattern, :limit => 3)
    end

    def render_list(name, pattern, options = {})
      posts = Post.find(pattern, options)
      write_html name, render_with_layout(:list, binding)
    end

    def write_html(label, html)
      Dir.mkdir @dist_dir unless File.exist?(@dist_dir)
      filename = File.join(@dist_dir, label + '.html')
      File.open(filename, 'w') {|f| f.write html }
      puts '  create ' + filename
    end

    def render_with_layout(template, b = binding)
      render(:layout) { render(template, b) }
    end

    def render(template, b = binding)
      haml = File.read(File.join(rootdir, "views/#{template}.haml"))
      Haml::Engine.new(haml).render(b)
    end
  end

  class Post
    def self.find(pattern, options = {})
      self.find_srcs(pattern, options).map {|e| Post.new(e) }
    end

    def self.find_srcs(pattern, options = {})
      files = Dir.chdir(@@posts_dir) { Dir.glob(pattern + '.{txt,html}') }.sort.reverse
      options[:limit] ? files[0, options[:limit]] : files 
    end

    def self.year_months
      result = {}
      files = find_srcs(Diary_pattern)
      first_year = files.last[/^\d{4}/]
      last_year = files.first[/^\d{4}/]
      (first_year..last_year).to_a.reverse.map do |year|
        result[year] = ('01'..'12').select {|month| find_srcs("#{year}#{month}*")[0] }
      end
      result
    end

    @@compilers = [[nil, lambda {|post| post.body }]]
    def self.add_compiler(extname = nil, &block)
      @@compilers.unshift [extname, block]
    end

    @@posts_dir = 'data'
    def self.posts_dir=(dir)
      @@posts_dir = dir
    end

    attr_reader :filename, :header, :body
    def initialize(filename)
      @filename = filename
      @header, @body = Dir.chdir(@@posts_dir) { File.read(@filename) }.split(/^__$/, 2)
      @header, @body = nil, @header unless @body
      @header and p(@header)
    end

    def label
      File.basename(filename, '.*')
    end

    def to_html
      (@@compilers.assoc(File.extname filename) || @@compilers.last)[1].call(self)
    rescue
      Haml::Helpers::html_escape $!
    end
  end
end
