require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'

require (File.join(File.dirname(__FILE__), 'ext', 'gecode', 'rakefile.rb')) 

GEM = "dep_selector"
GEM_VERSION = "0.0.1"
SUMMARY = "Given packages, versions, and a dependency graph, find a valid assignment of package versions"

spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false
  s.summary = SUMMARY
  s.description = s.summary
  s.authors = ["Christopher Walters", "Mark Anderson"]
  s.email = ["cw@opscode.com", "mark@opscode.com"]
#  s.homepage = HOMEPAGE
  s.add_dependency "gecoder-with-gecode", "= 1.0.0"
  s.require_path = 'lib'
  s.autorequire = GEM
  s.files = Dir.glob("lib/**/*")
  s.extensions << 'ext/gecode/extconf.rb'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{GEM}-#{GEM_VERSION}}
end

begin
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
    spec.spec_files = FileList['spec/**/*_spec.rb']
  end

  Spec::Rake::SpecTask.new(:rcov) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
  end
rescue LoadError
  task :spec do
    abort "Rspec is not available. (sudo) gem install rspec to run unit tests"
  end
end


