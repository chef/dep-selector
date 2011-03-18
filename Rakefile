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
require 'rake'

require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'

gemspec = eval(File.read('dep_selector.gemspec'))

Rake::GemPackageTask.new(gemspec).define

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

begin
  require 'rake/extensiontask'
  Rake::ExtensionTask.new('dep_gecode', gemspec)
rescue LoadError
  desc "Disabled: install rake-compiler to enable this"
  task :compile do
    abort "rake-compiler is not avabilable. (sudo) gem install rake-compiler"
  end
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.rspec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
    spec.pattern = 'spec/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
  end
rescue LoadError
  task :spec do
    abort "RSpec is not available. (sudo) gem install rspec to run unit tests"
  end
end


