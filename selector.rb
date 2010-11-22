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

  def gecode_model_vars
    packages.inject({}){|acc, elt| acc[elt.first] = elt.last.gecode_model_var ; acc }
  end

  # TODO [cw,2010/11/21]: See TODO in ObjectiveFunction
  def gecode_model_var_values
    packages.inject({}){|acc, elt| acc[elt.first] = (elt.last.gecode_model_var.value rescue nil) ; acc }
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
  attr_reader :sorted_triples

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
    if constraint.nil?
      range
    else
      raise "Can't match constraint: #{constraint}" unless constraint =~ /= ([\d.]+)/
        Range.new(@triple_to_index[$1], @triple_to_index[$1])
    end
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
#run_list = [["A", nil], ["B", "= 1.0.0"]]

# A=1.0.0, B=2.0.0, C=X
#run_list = [["A", nil], ["B", "= 2.0.0"]]

# A={1.0.0 | 2.0.0}, B={2.0.0 | 1.0.0}, C=1.0.0
#run_list = [["A", nil], ["C", "= 1.0.0"]]

# no soln
#run_list = [["A", "= 1.0.0"], ["B", "= 1.0.0"]]

# depends on what the objective function is
run_list = [["A", nil]]

#current_versions = {"A" => "1.0.0", "B" => "2.0.0"}
current_versions = {"A" => "2.0.0", "B" => "1.0.0"}

current_versions_densely_packed = current_versions.inject({}) do |acc, elt|
  acc[elt.first] = dep_graph.package(elt.first).densely_packed_versions["= #{elt.last}"].first
  acc
end

# we use the explicitly specified dependencies as a strong preference
# in our objective function
explicit_densely_packed_dependencies = run_list.inject({}){|acc, rli| acc[rli.first] = dep_graph.package(rli.first).densely_packed_versions[rli.last] ; acc }


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
pp dep_graph.gecode_model_vars

class ObjectiveFunction
  attr_reader :best_solution, :best_solution_value
  
  def initialize(&evaluation_block)
    @evaluate_solution = evaluation_block
    @best_solution_value = -1.0/0 # negative infinity
  end

  def consider(soln)
    puts "considering solution:"
    pp soln.gecode_model_vars
    
    if (new_soln_value = @evaluate_solution.call(soln)) > best_solution_value
      puts "better soln found: #{new_soln_value} > #{best_solution_value}"
      # TODO [cw,2010/11/21]: this is a janky way to extract the
      # bindings of a solution, because Gecode::Mixin doesn't seem to
      # have a way to store a particular solution in the middle of
      # solving. Is there a better way to do this?
      @best_solution = soln.gecode_model_var_values
      @best_solution_value = new_soln_value
    end
    
    puts "\n\n"
  end
end

objective_function = ObjectiveFunction.new do |soln|
  # Note: We probably have to filter out the unnecessary dependencies
  # that are nonetheless bound here so that we're not unjustly
  # punishing the solution under consideration for appearing to change
  # packages that will actually just get removed.
  edit_distance = current_versions_densely_packed.inject(0) do |acc, curr_version|
    # TODO [cw,2010/11/21]: This edit distance only increases when a
    # package that is currently deployed is changed, not when a new
    # dependency is added. I think there is an argument to be made
    # that also including new packages is worthy of an edit distance
    # bump, since the interpretation can be that any difference in
    # code that is run (not just changing existing code) could be
    # considered "infrastructure instability". This needs to be
    # considered.
    pkg_name, curr_version_densely_packed = curr_version
    if soln.packages.has_key?(pkg_name)
      pkg = soln.package(pkg_name)
      putative_version = pkg.gecode_model_var.value
      puts "#{pkg_name} going from #{curr_version_densely_packed} to #{putative_version}"
      acc -= 1 unless putative_version == curr_version_densely_packed
    end
    acc
  end
end

puts "Current versions:"
pp current_versions

# example of a simple objective function that is not powerful enough to express ours
#dep_graph.objective_function = dep_graph.package("A").gecode_model_var
#dep_graph.maximize! :objective_function

puts "\n\n"
dep_graph.each_solution do |soln|
  objective_function.consider(soln)
end

puts "variable assignments:"
pp objective_function.best_solution
objective_function.best_solution.keys.sort.each do |pkg_name|
  densely_packed_version = objective_function.best_solution[pkg_name]
  puts "#{pkg_name}: #{densely_packed_version} -> #{dep_graph.package(pkg_name).densely_packed_versions.sorted_triples[densely_packed_version]}"
end

