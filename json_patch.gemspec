# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "json/patch/version"

Gem::Specification.new do |s|
  s.name        = "json_patch"
  s.version     = JSON::Patch::VERSION
  s.authors     = ["Travis Vachon"]
  s.email       = ["travis@copious.com"]
  s.homepage    = ""
  s.summary     = %q{JSON patch implementation in ruby}
  s.description = %q{An implementation of JSON patch in Ruby.

http://tools.ietf.org/html/draft-pbryan-json-patch-01

Utilities for applying JSON patches to arbitary objects. To
participate in the patch protocol, classes can implement #apply_patch
}

  s.rubyforge_project = "json_patch"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "mocha"
  s.add_development_dependency "rspec"
  s.add_development_dependency "bson_ext"
  s.add_development_dependency "mongoid"
  s.add_development_dependency "gemfury"
end
