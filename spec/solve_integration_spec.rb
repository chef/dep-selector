require 'spec_helper'
require 'solve'

# The current version of solve (0.8.2) doesn't quite match the API we require.
# This will be remedied in a future release.
module Solve
  class Constraint

    def include?(v)
      satisfies?(v)
    end
  end
end

# Test that we can use duck typing to pass Solve's version and constraint
# types to dep-selector
describe "Integration with berkshelf solve" do

  let(:solve_graph) do
    graph = Solve::Graph.new

    graph.artifacts("top-level", "1.0.0")
      .depends("dep-package", ">= 0.0.0")

    graph.artifacts("dep-package", "1.0.0-beta")
    graph
  end

  let(:demands) { [["get-the-old-one"]] }

  let(:graph) { DepSelector::DependencyGraph.new }

  let(:solve_artifact_top_level) { solve_graph.artifacts("top-level", "1.0.0") }
  let(:solve_artifact_dep_package) { solve_graph.artifacts("dep-package", "1.0.0") }

  it "uses solve's artifact objects to describe the problem" do
    artifact = solve_artifact_top_level

    graph.package(artifact.name).add_version(artifact.version)
  end

  it "uses solve's dependencies to describe the problem" do
    artifact = solve_artifact_top_level
    dependency = solve_artifact_top_level.dependencies.first

    # Add packages to dep-selector's graph
    graph.package(solve_artifact_top_level.name).add_version(solve_artifact_top_level.version)
    graph.package(solve_artifact_dep_package.name).add_version(solve_artifact_dep_package.version)

    DepSelector::Dependency.new(graph.package(dependency.name), dependency.constraint)
    gecode_all_versions = [ graph.package(dependency.name) ]
    gecode_demands = [ DepSelector::SolutionConstraint.new(graph.package(artifact.name), Solve::Constraint.new(">= 0.0.0"))  ]

    selector = DepSelector::Selector.new(graph, (1.0))
    pp selector.find_solution(gecode_demands, gecode_all_versions)
  end

end
