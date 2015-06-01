$:.push File.expand_path("../lib", __FILE__)
require "mrspec/version"

Gem::Specification.new do |s|
  s.name        = "mrspec"
  s.version     = MRspec::VERSION
  s.authors     = ["Josh Cheek"]
  s.email       = ["josh.cheek@gmail.com"]
  s.homepage    = "https://github.com/JoshCheek/mrspec"
  s.summary     = %q{Minitest tests + RSpec's test runner}
  s.description = %q{Allows you to run Minitest tests and specs with RSpec's runner, thus you can write both Minitest and RSpec, side-by-side, and take advantage of the many incredibly helpful features it supports (primarily: better formatters, --colour, --fail-fast, and tagging).}
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = ['mrspec']
  s.require_paths = ['lib']

  s.add_dependency "rspec-core", "~> 3.0"
  s.add_dependency "minitest",   "~> 5.0"
  s.add_dependency "what_weve_got_here_is_an_error_to_communicate", "~> 0.0.2"

  s.add_development_dependency "haiti",    ">= 0.2.2", "< 0.3"
  s.add_development_dependency "cucumber", "~> 2.0"
  s.add_development_dependency "what_weve_got_here_is_an_error_to_communicate", "> 0"
end
