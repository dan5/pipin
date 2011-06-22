require 'pipin/version'
require 'haml'
require 'fileutils'

def rootdir() File.join(File.dirname(File.expand_path(__FILE__)), '..') end
def htmlsufix() '.html' end

module Pipin
  Date_pattern = '[0-9]' * 8 + '*'
  Post_pattern = '[0-9a-zA-Z]*'

  def self.command(cmd)
    __send__ "command_#{cmd}", *ARGV
  end

  def self.command_new(dir)
    File.exist?(dir) && raise("File exists - #{dir}")
    FileUtils.cp_r File.join(rootdir ,'templatefiles'), dir
    puts Dir.glob(File.join(dir, '**/*')).map {|e| '  create ' + e }
  end

  def self.command_build(dir = '.')
    load dir + '/pipinrc'
    build = Builder.new('public')
    build.render_sitemap
    build.render_archives
    build.render_posts
    build.render_list('index', '20*', :limit => 3)
  end

  class Builder
    def initialize(distdir)
      @distdir = distdir
    end

    def render_sitemap
      posts = Post.find(Post_pattern)
      write_html 'sitemap', render_with_layout(:sitemap, binding)
    end

    def render_archives
      years = Post.year_months
      write_html 'archives', render_with_layout(:archives, binding)
      # render month page
      years.each do |year, months|
        months.each do |month|
          name = year + month
          render_list(name, name + '*')
        end
      end
    end

    def render_posts
      Post.find(Post_pattern).each do |post|
        write_html post.label, render_with_layout(:post, binding)
      end
    end

    def render_list(name, pattern, options = {})
      posts = Post.find(pattern, options)
      write_html name, render_with_layout(:list, binding)
    end

    def write_html(label, html)
      Dir.mkdir @distdir unless File.exist?(@distdir)
      filename = File.join(@distdir, label + '.html')
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
    @@entries_dir = 'datasample'
    def self.find(pattern, options = {})
      self.find_file(pattern, options).map {|e| Post.new(e) }
    end

    def self.find_file(pattern, options = {})
      files = Dir.chdir(@@entries_dir) { Dir.glob(pattern + '.{txt,html}') }.sort.reverse
      options[:limit] ? files[0, options[:limit]] : files 
    end

    def self.year_months
      result = {}
      files = find_file(Date_pattern)
      first_year = files.last[/^\d{4}/]
      last_year = files.first[/^\d{4}/]
      (first_year..last_year).to_a.reverse.map do |year|
        result[year] = ('01'..'12').select {|month| find_file("#{year}#{month}*")[0] }
      end
      result
    end

    attr_reader :filename, :header, :body
    def initialize(filename)
      @filename = filename
      @header, @body = Dir.chdir(@@entries_dir) { File.read(@filename) }.split(/^__$/, 2)
      @header, @body = nil, @header unless @body
    end

    def label
      File.basename(filename, '.*')
    end

    def to_html
      body
    end
  end
end
