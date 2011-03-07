require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

simple_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}},
  ]

simple_cookbook_version_constraint_2 =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}},
   {"key"=>["C", "2.0.0"], "value"=>{}},
   {"key"=>["C", "3.0.0"], "value"=>{}}
  ]

simple_cookbook_version_constraint_3 =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>">= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
  ]

moderate_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>">= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{"D"=>">= 1.0.0"}},
   {"key"=>["C", "2.0.0"], "value"=>{"D"=>">= 2.0.0"}},
   {"key"=>["C", "3.0.0"], "value"=>{"D"=>">= 3.0.0"}},
   {"key"=>["C", "4.0.0"], "value"=>{"D"=>">= 4.0.0"}},
   {"key"=>["D", "1.0.0"], "value"=>{}},
   {"key"=>["D", "2.0.0"], "value"=>{}},
   {"key"=>["D", "3.0.0"], "value"=>{}},
   {"key"=>["D", "4.0.0"], "value"=>{}} 
  ]

moderate_cookbook_version_constraint_2 =
  [{"key"=>["A", "1.0"], "value"=>{"C"=>"< 4.0"}},
   {"key"=>["B", "1.0"], "value"=>{"C"=>"< 3.0"}},
   {"key"=>["C", "2.0"], "value"=>{"D"=>"> 1.0", "F"=>">= 0.0.0"}},
   {"key"=>["C", "3.0"], "value"=>{"D"=>"> 2.0", "E"=>">= 0.0.0"}},
   {"key"=>["D", "1.1"], "value"=>{}},
   {"key"=>["D", "2.1"], "value"=>{}},
   {"key"=>["E", "1.0"], "value"=>{}},
   {"key"=>["F", "1.0"], "value"=>{}},
  ]

moderate_cookbook_version_constraint_3 =
  [{"key"=>["a", "1.0"], "value"=>{"c"=>"< 4.0"}},
   {"key"=>["b", "1.0"], "value"=>{"c"=>"< 3.0"}},
   {"key"=>["c", "2.0"], "value"=>{"d"=>"> 1.0", "f"=>nil}},
   {"key"=>["c", "3.0"], "value"=>{"d"=>"> 2.0", "e"=>nil}},
   {"key"=>["d", "1.1"], "value"=>{}},
   {"key"=>["d", "2.1"], "value"=>{}},
   {"key"=>["e", "1.0"], "value"=>{}},
   {"key"=>["f", "1.0"], "value"=>{}},
   {"key"=>["g", "1.0"], "value"=>{"d"=>"> 5.0"}},
   {"key"=>["n", "1.1"], "value"=>{}},
   {"key"=>["n", "1.2"], "value"=>{}},
   {"key"=>["n", "1.10"], "value"=>{}},
   {"key"=>["depends_on_nosuch", "1.0"], "value"=>{"nosuch"=>nil}}
  ]

padding_packages =
  [{"key"=>["padding1", "1.0"], "value"=>{}},
   {"key"=>["padding2", "1.0"], "value"=>{}}
  ]

dependencies_whose_constraints_match_no_versions =
  [{"key"=>["A", "1.0"], "value"=>{}},
   {"key"=>["B", "1.0"], "value"=>{"A"=>"> 1.0"}},
   {"key"=>["C", "1.0"], "value"=>{"B"=>nil}},
   *padding_packages
  ]

dependency_on_non_existent_package =
  [{"key"=>["depends_on_nosuch", "1.0.0"], "value"=>{"nosuch"=>"= 2.0.0"}},
   {"key"=>["transitive_dep_on_nosuch", "1.0.0"], "value"=>{"depends_on_nosuch"=>nil}},
   *padding_packages
  ]

satisfiable_circular_dependency_graph =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{"A"=>"= 1.0.0"}}
  ]

unsatisfiable_circular_dependency_graph =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 1.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{"A"=>"= 2.0.0"}},
   {"key"=>["B", "2.0.0"], "value"=>{"A"=>"= 1.0.0"}},
   *padding_packages
  ]

describe DepSelector::Selector do
  
  describe "find_solution" do

    it "a simple set of constraints and includes transitive dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "a simple set of constraints and doesn't include unnecessary dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 2.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0"
                      })
    end

    it "a simple set of constraints and does not include unnecessary assignments" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 2.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0"
                      })
    end

    it "and indicates which solution constraint makes the system unsatisfiable if there is no solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint_2)
      setup_constraint(dep_graph, padding_packages)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["C", "= 3.0.0"],
                                ["padding1"]
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == unsatisfiable_solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('C')]
      end
    end

    it "can solve a moderately complex system with a unique solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["C", "= 4.0"],
                                ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0",
                        "C" => "4.0.0",
                        "D" => "4.0.0"
                      })
    end

    it "should find a solution regardless of the dependency graph having a package with a dependency constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "should fail to find a solution when a solution constraint constrains a package to a range that includes no versions" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      setup_constraint(dep_graph, padding_packages)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["A", "> 1.0"],
                                ["padding2"],
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.message.should == "Solution constraint (A > 1.0.0) does not match any versions"
        nse.unsatisfiable_solution_constraint.should == unsatisfiable_solution_constraints[1]
      end
    end

    it "should fail to find a solution when a solution constraint's dependency is constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["B"],
                                ["padding2"],
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == unsatisfiable_solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('A')]
      end
    end

    it "should fail to find a solution when a solution constraint's transitive dependency is constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["C"],
                                ["padding2"],
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == unsatisfiable_solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('A')]
      end
    end

    it "should find a solution if one can be found regardless of invalid dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "should fail to find a solution if a non-existent package is in the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      setup_constraint(dep_graph, padding_packages)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["nosuch"],
                                ["padding2"],
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.message.should == "Solution constraint (nosuch >= 0.0.0) specifies a package that does not exist in the dependency graph"
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
      end
    end

    it "should fail to find a solution if a package with an invalid dependency is a direct dependency of one of the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["depends_on_nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
        nse.disabled_non_existent_packages.should == [dep_graph.package('nosuch')]
        nse.disabled_most_constrained_packages.should == []
      end
    end

    it "should respect the authoritative list of extant packages if there is a solution constraint that refers to a package that has no registered versions (which would otherwise be considered non-existent)" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints, [dep_graph.package('nosuch')])
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.message.should == "Solution constraint (nosuch >= 0.0.0) does not match any versions"
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
      end
    end

    it "should respect the authoritative list of extant packages in the case of failure" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["depends_on_nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints, [dep_graph.package('nosuch')])
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('nosuch')]
      end
    end

    it "should fail to find a solution if a package with an invalid dependency is a transitive dependency of one of the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["transitive_dep_on_nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
        nse.disabled_non_existent_packages.should == [dep_graph.package('nosuch')]
        nse.disabled_most_constrained_packages.should == []
      end
    end

    it "should solve a circular dependency graph that has a valid solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, satisfiable_circular_dependency_graph)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "1.0.0"
                      })
    end

    it "should fail to find a solution for (and not infinitely recurse on) a dependency graph that does not have a valid solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, unsatisfiable_circular_dependency_graph)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["A", "= 1.0.0"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('B')]
      end
    end

    it "should indicate that the problematic package is the dependency that is constrained to no versions" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint_3)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["g"]
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.message.should == "Unable to satisfy constraints on package d due to solution constraint (g >= 0.0.0). Solution constraints that may result in a constraint on d: [(g = 1.0.0) -> (d > 5.0.0)]"
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('d')]
      end
    end

  end

  # TODO [cw,2011/2/4]: Add a test for a set of solution constraints
  # that contains multiple restrictions on the same package. Do the
  # same for a PackageVersion that has several Dependencies on the
  # same package, some satisfiable, some not.

end
