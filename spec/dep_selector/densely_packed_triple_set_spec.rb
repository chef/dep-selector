require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

require 'rubygems'
require 'dep_selector/densely_packed_triple_set'
require 'dep_selector/version_constraint'
require 'pp'

def dump_result(dep_graph, objective_function)
  puts "Results"
  objective_function.best_solution.keys.sort.each do |pkg_name|
    densely_packed_version = objective_function.best_solution[pkg_name]
    puts "#{pkg_name}: #{densely_packed_version} -> #{dep_graph.package(pkg_name).version_from_densely_packed_version(densely_packed_version)}"
  end
end

describe DepSelector::DenselyPackedSet do
  it "can create a simple set of versions and pick a version by equality" do
    dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
    constraint = DepSelector::VersionConstraint.new("= 2.0.0")
    range = dpt_set[constraint]
    range.first.should == 1
    range.last.should == 1
  end

  it "can create a simple set of versions and pick a version by greater than equal" do
    dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
    constraint = DepSelector::VersionConstraint.new(">= 2.0.0")
    range = dpt_set[constraint]
    range.first.should == 1
    range.last.should == 3
  end

  it "can create a simple set of versions and pick a version by greater than" do
    dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
    constraint = DepSelector::VersionConstraint.new("> 2.0.0")
    range = dpt_set[constraint]
    range.first.should == 2
    range.last.should == 3
  end
  
  it "can create a simple set of versions and pick a version by less than equal" do
    dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
    constraint = DepSelector::VersionConstraint.new("<= 3.0.0")
    range = dpt_set[constraint]
    range.first.should == 0
    range.last.should == 2
  end

  it "can create a simple set of versions and pick a version by less than equal" do
    dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
    constraint = DepSelector::VersionConstraint.new("<= 3.0.0")
    range = dpt_set[constraint]
    range.first.should == 0
    range.last.should == 2
  end

  it "can create a more complex set of versions and pick a version by >~ x.y" do
    dpt_set = DepSelector::DenselyPackedSet.new ["0.1.0", "1.0.0", "1.1", "1.1.1", "1.2", "1.2.1", "1.2.2",
                                                       "2.0.0", "3.0.0", "4.0.0"]
    constraint = DepSelector::VersionConstraint.new("~> 1.1")
    range = dpt_set[constraint]
    range.first.should == 2
    range.last.should == 6
  end
  it "can create a more complex set of versions and pick a version by ~> x.y.z" do
    dpt_set = DepSelector::DenselyPackedSet.new ["0.1.0", "1.0.0", "1.1", "1.1.1", "1.2", "1.2.1", "1.2.2",
                                                       "2.0.0", "3.0.0", "4.0.0"]
    constraint = DepSelector::VersionConstraint.new("~> 1.1.0")
    range = dpt_set[constraint]
    range.first.should == 2
    range.last.should == 3
  end
  
  it "errors if the densely packed version is requested for an invalid triple" do
    dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0"]
    lambda{ dpt_set.index("2.0.0") }.should raise_error(DepSelector::Exceptions::TripleNotDenselyPacked)
  end
end
