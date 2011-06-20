require "pipin/version"

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
  end
end
