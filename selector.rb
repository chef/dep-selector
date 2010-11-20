require 'rubygems'
require 'gecoder'
require 'chef/version_class'
require 'pp'

class Package
  @packages = {}
  
  class << self
    attr_accessor :packages

    def find(name)
      @packages = {} unless packages
      packages.has_key?(name) ? packages[name] : (packages[name]=Package.new(name))
    end

    def each
      packages.each do |name, pkg|
        yield pkg
      end
    end
  end
  
  attr_accessor :name, :versions
  
  def initialize(name)
    @name = name
    @versions = []

    self.class.packages[name] = self
  end
  
  def add_version(version)
    versions << (pv = PackageVersion.new(self, version))
    pv
  end

  def densely_packed_versions
    @densely_packed_versions ||= DenselyPackedTripleSet.new(versions.map{|pkg_version| pkg_version.version})
  end

  def gecode_model_var(model)
    @gecode_model_var ||= model.int_var(densely_packed_versions.range)
  end
  
  def generate_gecode_constraints(model)
    versions.each{|version| version.generate_gecode_constraints(model) }
    gecode_model_var(model)
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

  def add_dependency(package, constraint)
    dependencies << [package, constraint]
#    pp :dependencies => dependencies, :pkg_name => package_name, :version => version
  end
  
  def generate_gecode_constraints(model)
    pkg_mv = package.gecode_model_var(model)
    pkg_densely_packed_version = package.densely_packed_versions["= #{version}"].first
    guard = (pkg_mv.must == pkg_densely_packed_version)
#    pp :densely_packed_version_first => pkg_densely_packed_version, :pkg => package_name, :version => version, :guard => true
    conjunction = dependencies.inject(guard) do |acc, dep_pair|
      dep_pkg = dep_pair.first
      dep_pkg_mv = dep_pkg.gecode_model_var(model)
      dep_densely_packed_versions = dep_pkg.densely_packed_versions[dep_pair.last]
#      pp :dep_pkg_name => dep_pkg.name, :dep_range => dep_densely_packed_versions, :pkg_name => package_name, :version => version
      acc & dep_pkg_mv.must_be.in(dep_densely_packed_versions)
    end
    conjunction | (pkg_mv.must_not == pkg_densely_packed_version)
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

cookbook_versions.each do |cb_version|
#  pp :cb_version => cb_version
  pv = Package.find(cb_version["key"].first).add_version(cb_version["key"].last)
  cb_version['value'].each_pair do |dep_name, constraint|
    pkg = Package.find(dep_name)
    pv.add_dependency(pkg, constraint)
  end
end

model = Gecode::Model.new

# add cookbook dependency graphs to gecode model
Package.each do |pkg|
  pkg.generate_gecode_constraints(model)
end


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
  pkg = Package.find(run_list_item.first)
  constraint = run_list_item.last
  
  pkg_mv = pkg.gecode_model_var(model)
  if constraint
    pkg_mv.must_be.in(pkg.densely_packed_versions[constraint])
  end
  model.branch_on(pkg_mv)
end

puts "packages and valid versions:"
Package.each do |pkg|
  pp :pkg => pkg.name, :value => pkg.gecode_model_var(model)
end

soln = model.solve!

puts "variable assignments:"
Package.each do |pkg|
  puts "#{pkg.name}: #{pkg.gecode_model_var(model).value rescue "unassigned"}"
end
