require 'rubygems'
require 'dep_selector'
require 'pp'


# gets cookbook versions and stuffs into our model
#cookbook_versions = Chef::CookbookVersion.cdb_list_cookbook_version_dependencies
cookbook_versions =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}}]

dep_graph = DepSelector::DependencyGraph.new

cookbook_versions.each do |cb_version|
#  pp :cb_version => cb_version
  pv = dep_graph.package(cb_version["key"].first).add_version(cb_version["key"].last)
  cb_version['value'].each_pair do |dep_name, constraint|
    pv.dependencies << DepSelector::Dependency.new(dep_graph.package(dep_name), constraint)
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


objective_function = DepSelector::ObjectiveFunction.new do |soln|
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

