require 'rubygems'
require 'gecoder'
require 'chef/version_class'
require 'pp'


# DependencyGraphs contain Packages, which in turn contain
# PackageVersions
class DependencyGraph
  include Gecode::Mixin

  attr_reader :packages

  def initialize
    @packages = {}
  end

  def package(name)
    packages.has_key?(name) ? packages[name] : (packages[name]=Package.new(self, name))
  end

  def each_package
    packages.each do |name, pkg|
      yield pkg
    end
  end

  def generate_gecode_constraints
    each_package{ |pkg| pkg.generate_gecode_constraints }
  end
end

class Package
  attr_reader :dependency_graph, :name, :versions
  
  def initialize(dependency_graph, name)
    @dependency_graph = dependency_graph
    @name = name
    @versions = []
  end
  
  def add_version(version)
    versions << (pv = PackageVersion.new(self, version))
    pv
  end

  def densely_packed_versions
    @densely_packed_versions ||= DenselyPackedTripleSet.new(versions.map{|pkg_version| pkg_version.version})
  end

  # Note: only invoke this method after all PackageVersions have been added
  def gecode_model_var
    @gecode_model_var ||= dependency_graph.int_var(densely_packed_versions.range)
  end
  
  def generate_gecode_constraints
    versions.each{|version| version.generate_gecode_constraints }
  end
end

class DenselyPackedTripleSet
  def initialize(triples)
    @sorted_triples = triples.map{|triple| Chef::Version.new(triple) }.sort
    @triple_to_index = {}
    @sorted_triples.each_with_index{|triple, idx| @triple_to_index[triple.to_s] = idx}
  end

  def range
    Range.new(0, @sorted_triples.size-1)
  end

  # TODO: make this method respect more than just the = operator
  def [](constraint)
    raise "Can't match constraint: #{constraint}" unless constraint =~ /= ([\d.]+)/
    Range.new(@triple_to_index[$1], @triple_to_index[$1])
  end
end

class PackageVersion
  attr_accessor :package, :version, :dependencies

  def initialize(package, version)
    @package = package
    @version = version
    @dependencies = []
  end

  def generate_gecode_constraints
    pkg_mv = package.gecode_model_var
    pkg_densely_packed_version = package.densely_packed_versions["= #{version}"].first

    guard = (pkg_mv.must == pkg_densely_packed_version)
    conjunction = dependencies.inject(guard){ |acc, dep| acc & dep.generate_gecode_constraint }
    conjunction | (pkg_mv.must_not == pkg_densely_packed_version)
  end
end

class Dependency
  attr_reader :package, :constraint

  def initialize(package, constraint)
    @package = package
    @constraint = constraint
  end

  def generate_gecode_constraint
    package.gecode_model_var.must_be.in(package.densely_packed_versions[constraint])
  end
end



#################################


# gets cookbook versions and stuffs into our model
#cookbook_versions = Chef::CookbookVersion.cdb_list_cookbook_version_dependencies
cookbook_versions =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}}]

dep_graph = DependencyGraph.new

cookbook_versions.each do |cb_version|
#  pp :cb_version => cb_version
  pv = dep_graph.package(cb_version["key"].first).add_version(cb_version["key"].last)
  cb_version['value'].each_pair do |dep_name, constraint|
    pv.dependencies << Dependency.new(dep_graph.package(dep_name), constraint)
  end
end

# add cookbook dependency graphs to gecode model
dep_graph.generate_gecode_constraints


# A=2.0.0, B=1.0.0, C=X
run_list = [["A", nil], ["B", "= 1.0.0"]]

# A=1.0.0, B=2.0.0, C=X
#run_list = [["A", nil], ["B", "= 2.0.0"]]

# A={1.0.0 | 2.0.0}, B={2.0.0 | 1.0.0}, C=1.0.0
#run_list = [["A", nil], ["C", "= 1.0.0"]]

# no soln
#run_list = [["A", "= 1.0.0"], ["B", "= 1.0.0"]]

# add run list-generated constraints, which are the only variables
# that we explicitly branch on.
run_list.each do |run_list_item|
  pkg = dep_graph.package(run_list_item.first)
  constraint = run_list_item.last
  
  pkg_mv = pkg.gecode_model_var
  if constraint
    pkg_mv.must_be.in(pkg.densely_packed_versions[constraint])
  end
  dep_graph.branch_on(pkg_mv)
end

puts "packages and valid versions:"
dep_graph.each_package do |pkg|
  pp :pkg => pkg.name, :value => pkg.gecode_model_var
end

soln = dep_graph.solve!

puts "variable assignments:"
dep_graph.each_package do |pkg|
#  puts "#{pkg.name}: #{pkg.gecode_model_var.value}"
  pp :pkg => pkg.name, :value => pkg.gecode_model_var
end
