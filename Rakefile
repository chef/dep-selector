#
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Mark Anderson (<mark@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rubygems'
# TODO: Think about bundler
require 'rake'
require 'jeweler'

require 'rake/extensiontask'

require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'

#require (File.join(File.dirname(__FILE__), 'ext', 'gecode', 'rakefile.rb')) 

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
  s.homepage = %q{http://github.com/algorist/dep_selector}
  s.require_path = 'lib'
  s.requirements << 'gecode, version 3.5 or greater'
  s.requirements << 'g++'
  s.files = Dir.glob("lib/**/*.{rb}") + Dir.glob("ext/**/*.{i,c,cxx,h,cpp,rb}")
  s.extensions = FileList["ext/**/extconf.rb"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{GEM}-#{GEM_VERSION}}
end

Rake::ExtensionTask.new('dep_gecode', spec)

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


