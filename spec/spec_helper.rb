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

def setup_soln_constraints(dep_graph, soln_constraints)
  soln_constraints.map do |elt|
    pkg = dep_graph.package(elt.shift)
    constraint = DepSelector::VersionConstraint.new(elt.shift)
    DepSelector::SolutionConstraint.new(pkg, constraint)
  end
end

def verify_solution(observed, expected)
  versions = expected.inject({}){|acc, elt| acc[elt.first]=DepSelector::Version.new(elt.last) ; acc}
  observed.should == versions
end
