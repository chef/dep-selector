require 'rubygems'
require 'dep_selector'

def setup_constraint(dep_graph, cset)
  cset.each do |cb_version|
    pv = dep_graph.package(cb_version["key"].first).add_version(cb_version["key"].last)
    cb_version['value'].each_pair do |dep_name, constraint_str|
      constraint = DepSelector::VersionConstraint.new(constraint_str)
      pv.dependencies << DepSelector::Dependency.new(dep_graph.package(dep_name), constraint)
    end
  end
end

def add_run_list(dep_graph, run_list)
  run_list.each do |run_list_item|
    pkg = dep_graph.package(run_list_item.first)
    constraint = run_list_item.last
    
    pkg_mv = pkg.gecode_model_var
    if constraint
      pkg_mv.must_be.in(pkg.densely_packed_versions[constraint])
    end
    dep_graph.branch_on(pkg_mv)
  end
end
