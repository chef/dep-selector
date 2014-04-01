$:.unshift(File.expand_path("../lib", __FILE__))
require 'dep_selector/dep_selector_version'

Gem::Specification.new do |s|
  s.name = "dep_selector"
  s.version = DepSelector::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false
  s.summary = "Given packages, versions, and a dependency graph, find a valid assignment of package versions"
  s.description = s.summary
  s.license = 'Apache v2'
  s.authors = ["Christopher Walters", "Mark Anderson"]
  s.email = ["dev@getchef.com"]
  s.homepage = %q{http://github.com/opscode/dep-selector}
  s.require_path = 'lib'
  s.requirements << 'gecode, version 3.5 or greater'
  s.requirements << 'g++'
  s.files = Dir.glob("lib/**/*.{rb}") + Dir.glob("ext/**/*.{i,c,cxx,h,cpp,rb}")
  s.extensions = Dir["ext/**/extconf.rb"]

  s.required_ruby_version = ">= 1.9.2"

  s.add_development_dependency "rspec", "~> 2.14"
  s.add_development_dependency "rake-compiler", "~> 0.9.2"
end
