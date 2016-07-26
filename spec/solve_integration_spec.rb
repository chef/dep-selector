require 'spec_helper'
require 'solve'
require 'solve/constraint'

# Test that we can use duck typing to pass Solve's version and constraint
# types to dep-selector
describe "Integration with berkshelf solve" do

  let(:solve_graph) do
    graph = Solve::Graph.new

    graph.artifact("top-level", "1.0.0")
      .depends("dep-package", ">= 0.0.0")

    graph.artifact("dep-package", "1.0.0-beta")
    graph
  end

  let(:demands) { [["get-the-old-one"]] }

  let(:graph) { DepSelector::DependencyGraph.new }

  let(:solve_artifact_top_level) { solve_graph.artifact("top-level", "1.0.0") }
  let(:solve_artifact_dep_package) { solve_graph.artifact("dep-package", "1.0.0") }

  it "uses solve's artifact objects to describe the problem" do
    artifact = solve_artifact_top_level

    package_version = graph.package(artifact.name).add_version(artifact.version)
    package_version.version.should == Semverse::Version.new("1.0.0")
  end

  it "uses solve's constraints to find matching packages" do
    artifact = solve_artifact_top_level

    package_version = graph.package(artifact.name).add_version(artifact.version)
    package = graph.package(artifact.name)

    package[Solve::Constraint.new(">= 0.0.0")].should == [ package_version ]
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
    solution = selector.find_solution(gecode_demands, gecode_all_versions)
    solution.should == { "top-level" => Semverse::Version.new("1.0.0") }
  end

end
