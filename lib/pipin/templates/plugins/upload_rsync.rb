require 'pty'
require 'expect'

def upload_rsync
  opt = '-acvz -e ssh'
  opt += ' --delete' if config[:rsync][:delete]
  src = config[:dir][:dist]
  dst = config[:rsync][:dist]
  puts cmd = "  rsync #{opt} #{src} #{dst}"
  PTY.spawn(cmd) do |r, w|
    r.expect(/password:/, timeout = 30) { w.puts config[:rsync][:password] }
    puts r.read
  end
end

if defined?(task) and config[:upload] == :rsync
  task :upload => [:default, :upload_rsync]
  task :upload_rsync do
    upload_rsync
  end
end

if __FILE__ == $0
  $LOAD_PATH.unshift '../lib'
  require 'pipin'
  load './pipinrc'
  setup_environment
  rsync
end
