# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pipin/version"

Gem::Specification.new do |s|
  s.name        = "pipin"
  s.version     = Pipin::VERSION
  s.authors     = ["dan5"]
  s.email       = ["dan5.ya@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{blog}
  s.description = %q{simple blog system}

  s.rubyforge_project = "pipin"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
