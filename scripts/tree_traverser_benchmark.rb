$:.unshift File.expand_path("../../lib", __FILE__)
require 'dep_selector'
require 'benchmark'

N = 1000
require 'pp'

$transitive_deps_1 =
  [{"key"=>["A", "1.0.0"], "value"=>{"X"=>">= 1.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"X"=>"= 2.0.0"}},

   {"key"=>["B", "1.0.0"], "value"=>{}},

   {"key"=>["C", "1.0.0"], "value"=>{"A"=>nil}},

   {"key"=>["D", "1.0.0"], "value"=>{"A"=>"= 2.0.0", "X"=>"= 1.0.0"}},

   {"key"=>["X", "1.0.0"], "value"=>{}},
   {"key"=>["X", "2.0.0"], "value"=>{}}
  ]

$transitive_deps_2 =
  [{"key"=>["A", "1.0.0"], "value"=>{"L"=>">= 1.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"L"=>"= 2.0.0"}},
   {"key"=>["A", "3.0.0"], "value"=>{"X"=>nil}},

   {"key"=>["B", "1.0.0"], "value"=>{"X"=>">= 1.0.0"}},
   {"key"=>["B", "2.0.0"], "value"=>{}},

   {"key"=>["C", "1.0.0"], "value"=>{"X"=>"= 3.0.0"}},

   {"key"=>["D", "1.0.0"], "value"=>{"X"=>nil}},

   {"key"=>["L", "1.0.0"], "value"=>{"X"=>"= 1.0.0"}},
   {"key"=>["L", "2.0.0"], "value"=>{"X"=>"= 2.0.0"}},

   {"key"=>["X", "1.0.0"], "value"=>{}},
   {"key"=>["X", "2.0.0"], "value"=>{}},
   {"key"=>["X", "3.0.0"], "value"=>{}},
  ]

$dependency_on_non_existent_package =
  [{"key"=>["depends_on_nosuch", "1.0.0"], "value"=>{"nosuch"=>"= 2.0.0"}},
   {"key"=>["transitive_dep_on_nosuch", "1.0.0"], "value"=>{"depends_on_nosuch"=>nil}}
  ]


def setup_soln_constraints(dep_graph, soln_constraints)
  soln_constraints.map do |elt|
    pkg = dep_graph.package(elt.shift)
    constraint = DepSelector::VersionConstraint.new(elt.shift)
    DepSelector::SolutionConstraint.new(pkg, constraint)
  end
end

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

def setup
  dep_graph = DepSelector::DependencyGraph.new
  setup_constraint(dep_graph, $transitive_deps_1)

  solution_constraints =
    setup_soln_constraints(dep_graph,
                           [
                            ["X", "> 1.0.0"],
                            ["D"]
                           ])
  [dep_graph, solution_constraints]
end

def run_error_reporter(dep_graph, solution_constraints)
  er = DepSelector::ErrorReporter::SimpleTreeTraverser.new
  er.give_feedback(dep_graph, solution_constraints, 1, dep_graph.package('X'))
end

$dep_graph, $solution_constraints = setup


Benchmark.bm(10) do |x|
  x.report("report:") do
    #require 'profile'
    N.times { run_error_reporter($dep_graph, $solution_constraints) }
  end
end
