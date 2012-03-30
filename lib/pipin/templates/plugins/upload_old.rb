require 'net/ftp'
require 'pty'
require 'expect'
require 'yaml'

Db_fname = 'session.yaml'

def session
  $session ||= YAML.load(File.read(Db_fname))
rescue Errno::ENOENT
  {}
end

def save_session
  File.write(Db_fname, session.to_yaml)
end

def upload
  srcs = src_filenames
  yield srcs unless srcs.empty?
  session[:updated_at] = Time.now
  save_session
end

def src_filenames
  srcs = Dir.glob(config[:dir][:dist] + '/*').delete_if {|src| File.directory?(src) }
  srcs.select! {|src| File.mtime(src) > session[:updated_at] } if session[:updated_at]
  srcs
end

def upload_ftp
  upload do |srcs|
    ftp = Net::FTP.new
    ftp.connect config[:ftp][:server]
    ftp.login config[:ftp][:user], config[:ftp][:password]
    ftp.binary = true
    ftp.chdir config[:ftp][:dist]
    srcs.each do |e|
      puts "  ftp.put #{e}"
      ftp.put e 
    end
    ftp.quit
  end
end

def upload_scp
  upload do |srcs|
    dist_dir = 'upload_temp'
    setup_tempdir(dist_dir)
    srcs.each {|src| FileUtils.cp src, dist_dir }
    puts cmd = "  scp #{dist_dir}/* #{config[:scp][:dist]}"
    PTY.spawn(cmd) do |r, w|
      r.expect(/password:/, timeout = 30) { w.puts config[:scp][:password] }
      puts r.read
    end
  end
end

def setup_tempdir(dir)
  FileUtils.rm_r dir if File.exist?(dir)
  Dir.mkdir dir
end

if defined?(task) and config[:upload] and [:scp, :ftp].include?(config[:upload])
  meth = "upload_#{config[:upload]}"
  task :upload => [:default, meth]
  task meth do
    send meth
  end
end

if __FILE__ == $0
  $LOAD_PATH.unshift '../lib'
  require 'pipin'
  load './pipinrc'
  setup_environment
  #upload_scp
  upload_ftp
end
