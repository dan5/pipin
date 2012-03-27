require 'pipin'
require 'rake/clean'

def dst_html(label)
  File.join DSTDIR, "#{label}.html"
end

setup_environment

SRCDIR = Pipin::Post.posts_dir
DSTDIR = 'public'
SRC_EXTNAMES = %w(html txt)
EXTS = SRC_EXTNAMES.join(',')

DIARY_SRCS = FileList["#{SRCDIR}/#{Pipin::Diary_pattern}.{#{EXTS}}"]
SRCS = FileList["#{SRCDIR}/#{Pipin::Post_pattern}.{#{EXTS}}"]
DSTS = SRCS.pathmap("#{DSTDIR}/%n.html")
MONTH_DSTS = Pipin::Post.year_months.map {|year, months|
  months.map {|month| dst_html(year + month) }
}.flatten

task :default => [:index, :archives, :months, :sitemap] + DSTS.sort.reverse

# posts
SRC_EXTNAMES.each do |extname|
  rule /public\/\w+\.html/ => "#{SRCDIR}/%n.#{extname}" do |t|
    Pipin::Exec.new('post', File.basename(t.name, '.html')).build
  end
end

# mouths
task :months => MONTH_DSTS
Pipin::Post.year_months.each do |year, months|
  months.each do |month|
    dst = dst_html(year + month)
    srcs = FileList["#{SRCDIR}/#{year + month}[0-9][0-9]*.{#{EXTS}}"]
    file dst => srcs do
      Pipin::Exec.new('month', year, month).build
    end
  end
end

# other
OTHER_TASKS ={
  'index' => DIARY_SRCS.sort.reverse[0, 3],
  'archives' => DIARY_SRCS,
  'sitemap' => SRCS,
}
OTHER_TASKS.each do |pagename, srcs|
  dst = dst_html(pagename)
  task pagename => dst
  file dst => srcs do
    Pipin::Exec.new(pagename).build
  end
end

# clean
OTHER_DSTS = OTHER_TASKS.keys.map {|page| dst_html(page) }
CLEAN.include(DSTS, MONTH_DSTS, OTHER_DSTS)
