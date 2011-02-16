require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
	
namespace :gecode do

  task :default => :make

  swig_out = 'dep_selector_swig_wrap.cxx'

  desc "Make gecode wrapper"
  task :make =>["Makefile", swig_out] do
    sh "make"
  end
  desc "Cleanup gecode wrapper"
  task :clean do
    sh "make clean"
  end
  desc "MKMF gecode wrapper"
  file "Makefile" => ["extconf.rb"] do
    sh "ruby extconf.rb"
  end
  
  desc "Make wrapper from swig code"
  file swig_out => [ 'dep_selector_swig.i' ] do |t|
    cmd = "swig -c++ -ruby #{t.prerequisites[0]}"
    sh cmd
  end
  
  task :make_clean => [:clean, :mkmf, :make]      
  
end
