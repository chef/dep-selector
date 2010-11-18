require 'rubygems'
require 'gecoder'

class Package
  @packages = {}
  
  class << self
    attr_accessor :packages

    def find(name)
      @packages = {} unless packages
      packages.has_key?(name) ? packages[name] : packages[name] = Package.new(name)
    end

    def list
      packages.keys
    end
  end
  
  attr_accessor :name, :valid_versions, :versions
  
  def initialize(name)
    @name = name
#    @valid_versions = valid_versions
    @versions = []

    self.class.packages[name] = self
  end
  
  def add_version(version)
    versions << (pv = PackageVersion.new(name, version))
#    pp :package_versions => versions
    pv
  end
  
  def densely_packed_versions
    @densely_packed_versions ||= DenselyPackedTripleSet.new(versions.map{|pkg_version| pkg_version.version})
  end

  def gecode_model_var(model)
    @gecode_var ||= model.int_var(densely_packed_versions.range)
  end
  
  def generate_gecode_constraints(model)
    versions.each{|version| version.generate_gecode_constraints(model) }
  end
end

class DenselyPackedTripleSet
  attr_accessor :sorted_triples, :triple_to_index
  
  def initialize(triples)
#    @sorted_triples = triples.sort{|t1, t2| Chef::Version.new(t1) <=> Chef::Version.new(t2) }
    @sorted_triples = triples.map{|triple| Chef::Version.new(triple) }.sort
    @triple_to_index = {}
    @sorted_triples.each_with_index{|triple, idx| @triple_to_index[triple.to_s] = idx}
  end

  def range
    Range.new(0, sorted_triples.size-1)
  end

  def [](constraint)
    raise "Can't match constraint: #{constraint}" unless constraint =~ /= ([\d.]+)/
    pp :triple_to_index => triple_to_index
    pp :dol1 => $1
    pp :triple_to_index_dol1 => triple_to_index[$1]
    Range.new(triple_to_index[$1], triple_to_index[$1])
  end
end

class PackageVersion
  attr_accessor :package_name, :version, :dependencies

  def initialize(package_name, version)
    @package_name = package_name
    @version = version
    @dependencies = []
  end

  def add_dependency(package, constraint)
    dependencies << [package, constraint]
  end
  
  def gecode_data(model, pkg_name, version)
    pkg = Package.find(package_name)
    densely_packed_version = pkg.densely_packed_versions["= #{version}"]
    [pkg.gecode_model_var(model), densely_packed_version]
  end
  
  def generate_gecode_constraints(model)
    pkg, densely_packed_version = gecode_data(model, package_name, version)
    guard = pkg.must_be.in(densely_packed_version)
    conjunction = dependencies.inject(guard) do |acc, dep|
      dep_pkg, dep_densely_packed_version = gecode_data(model, dep.first, dep.last)
      acc & dep_pkg.must_be.in(dep_densely_packed_version)
      acc
    end
    conjunction | (pkg.must_not_be.in(densely_packed_version))
  end
end

# class Constraint
#   attr_accessor :value
  
#   def initialize(value)
#     @value = value
#   end

#   def gecode(model, d)
#   end
# end

#################################


# gets cookbook versions and stuffs into our model
cookbook_versions = Chef::CookbookVersion.cdb_list_cookbook_version_dependencies
cookbook_versions.each do |cb_version|
#  pp :cb_version => cb_version
  pv = Package.find(cb_version["key"].first).add_version(cb_version["key"].last)
  cb_version['value'].each_pair do |dep_name, constraint|
    pkg = Package.find(dep_name)
#    c = Constraint.new(constraint)
#    pp :pkg => pkg, :c => c
    pv.add_dependency(pkg, constraint)
  end
end

puts "#" * 100
#Package.list.each{|pkg_name| pp :name => pkg_name, :versions => Package.find(pkg_name).versions }


# Package.list.map{|pkg_name| Package.find(pkg_name) }.each do |pkg|
#   packed = pkg.densely_packed_versions
#   pp packed["= 1.0.0"]
# end


model = Gecode::Model.new

# adds cookbook dependency graphs to model
Package.list.map{|pkg_name| Package.find(pkg_name)}.each do |pkg|
  pkg.generate_gecode_constraints(model)
#   pkg.versions.each do |pkg_version|
#     pkg_version.generate_clause(model)
#   end
end


soln = model.solve!
Package.list.map{|pkg_name| Package.find(pkg_name)}.each do |pkg|
  puts "#{pkg.name}: #{pkg.gecode_model_var.value}"
end
