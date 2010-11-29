require 'rubygems'
require 'dep_selector'
require 'pp'

def setup_constraint(dep_graph, cset)
  cset.each do |cb_version|
    package_name = cb_version["key"].first
    version = DepSelector::Version.new(cb_version["key"].last)
    dependencies = cb_version['value']

    pv = dep_graph.package(package_name).add_version(version)
    dependencies.each_pair do |dep_name, constraint_str|
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

def verify_solution(observed, expected)
  versions = expected.inject({}){|acc, elt| acc[elt.first]=DepSelector::Version.new(elt.last) ; acc}
  observed.should == versions
end
