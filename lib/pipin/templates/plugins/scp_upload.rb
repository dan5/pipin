require 'pty'
require 'expect'

def scp_upload
  dist_dir = 'upload_srcs'
  FileUtils.rm_r dist_dir if File.exist?(dist_dir)
  Dir.mkdir dist_dir

  srcs = Pipin::Builder.distfiles
  srcs.each {|src| FileUtils.cp src, dist_dir }

  scp_upload_(dist_dir + '/*', config[:scp][:dist], config[:scp][:password])
end

def scp_upload_(src, dist, password)
  timeout = 30
  cmd = "scp #{src} #{dist}"
  puts "  #{cmd}"
  PTY.spawn(cmd) do |r, w|
    r.expect(/password:/, timeout) { w.puts password }
    puts r.read
  end
end

if config[:upload] == :scp
  task :upload => [:default, :scp_upload]
  task :scp_upload do
    scp_upload
  end
end
