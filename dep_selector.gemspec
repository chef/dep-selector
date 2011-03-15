Gem::Specification.new do |s|
  s.name = "dep_selector"
  s.version = "0.0.1"
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false
  s.summary = "Given packages, versions, and a dependency graph, find a valid assignment of package versions"
  s.description = s.summary
  s.license = 'Apache v2'
  s.authors = ["Christopher Walters", "Mark Anderson"]
  s.email = ["cw@opscode.com", "mark@opscode.com"]
  s.homepage = %q{http://github.com/algorist/dep_selector}
  s.require_path = 'lib'
  s.requirements << 'gecode, version 3.5 or greater'
  s.requirements << 'g++'
  s.files = Dir.glob("lib/**/*.{rb}") + Dir.glob("ext/**/*.{i,c,cxx,h,cpp,rb}")
  s.extensions = Dir["ext/**/extconf.rb"]
end
