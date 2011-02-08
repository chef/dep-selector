require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
	
namespace :gecode do

task :default => :make

desc "Make gecode wrapper"
task :make => 'Makefile' do
  sh "make"
end
desc "Cleanup gecode wrapper"
task :clean do
  sh "make clean"
end
desc "MKMF gecode wrapper"
task :mkmf do
  sh "ruby extconf.rb"
end

#
# Broken:
# swig -c++ -ruby dep_selector_swig.i
# :3: Error: Unable to find 'ruby.swg'
# 
desc "Make wrapper from swig code"
file "dep_selector_swig_wrap.cxx" => [ 'dep_selector_swig.i' ] do |t|
  puts "SWIG : #{t.prerequisites[0]}"
  cmd = "swig -c++ -ruby #{t.prerequisites[0]}"
  puts "SWIG : #{cmd}"
  sh cmd
end

task :make_clean => [:clean, :mkmf, :make]      

end
