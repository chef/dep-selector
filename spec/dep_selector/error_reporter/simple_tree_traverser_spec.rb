require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

transitive_deps_1 =
  [{"key"=>["A", "1.0.0"], "value"=>{"X"=>">= 1.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"X"=>"= 2.0.0"}},

   {"key"=>["B", "1.0.0"], "value"=>{}},

   {"key"=>["C", "1.0.0"], "value"=>{"A"=>nil}},

   {"key"=>["D", "1.0.0"], "value"=>{"A"=>"= 2.0.0", "X"=>"= 1.0.0"}},

   {"key"=>["X", "1.0.0"], "value"=>{}},
   {"key"=>["X", "2.0.0"], "value"=>{}}
  ]

transitive_deps_2 =
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

dependency_on_non_existent_package =
  [{"key"=>["depends_on_nosuch", "1.0.0"], "value"=>{"nosuch"=>"= 2.0.0"}},
   {"key"=>["transitive_dep_on_nosuch", "1.0.0"], "value"=>{"depends_on_nosuch"=>nil}}
  ]

describe DepSelector::ErrorReporter::SimpleTreeTraverser do

  describe "give_feedback" do

    it "finds constraints on the target package in the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, transitive_deps_1)

      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["X", "> 1.0.0"],
                                ["D"]
                               ])
      er = DepSelector::ErrorReporter::SimpleTreeTraverser.new
      er.give_feedback(dep_graph, solution_constraints, 1, dep_graph.package('X')).should ==
        "Unable to satisfy constraints on package X due to solution constraint (D >= 0.0.0). Solution constraints that may result in a constraint on X: [(X > 1.0.0)], [(D = 1.0.0) -> (A = 2.0.0) -> (X = 2.0.0)], [(D = 1.0.0) -> (X = 1.0.0)]"
    end

    it "finds constraints on the target package in first-level dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, transitive_deps_1)

      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["D"]
                               ])
      er = DepSelector::ErrorReporter::SimpleTreeTraverser.new
      er.give_feedback(dep_graph, solution_constraints, 1, dep_graph.package('X')).should ==
        "Unable to satisfy constraints on package X due to solution constraint (D >= 0.0.0). Solution constraints that may result in a constraint on X: [(A = 1.0.0) -> (X >= 1.0.0)], [(A = 2.0.0) -> (X = 2.0.0)], [(D = 1.0.0) -> (A = 2.0.0) -> (X = 2.0.0)], [(D = 1.0.0) -> (X = 1.0.0)]"
    end

    it "finds constraints on the target package in transitive dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, transitive_deps_1)

      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["C"],
                                ["D"]
                               ])
      er = DepSelector::ErrorReporter::SimpleTreeTraverser.new
      er.give_feedback(dep_graph, solution_constraints, 1, dep_graph.package("X")).should ==
        "Unable to satisfy constraints on package X due to solution constraint (D >= 0.0.0). Solution constraints that may result in a constraint on X: [(C = 1.0.0) -> (A = 1.0.0) -> (X >= 1.0.0)], [(C = 1.0.0) -> (A = 2.0.0) -> (X = 2.0.0)], [(D = 1.0.0) -> (A = 2.0.0) -> (X = 2.0.0)], [(D = 1.0.0) -> (X = 1.0.0)]"
    end

    it "should construct all paths from the solution constraint packages to the most constrained package and collapse paths that have exactly one difference on the version selected of the same package" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, transitive_deps_2)

      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A", "<= 2.0.0"],
                                ["B"],
                                ["C"],
                                ["D"]
                               ])
      er = DepSelector::ErrorReporter::SimpleTreeTraverser.new
      er.give_feedback(dep_graph, solution_constraints, 2, dep_graph.package("X")).should ==
        "Unable to satisfy constraints on package X due to solution constraint (C >= 0.0.0). Solution constraints that may result in a constraint on X: [(A = 1.0.0) -> (L = 1.0.0) -> (X = 1.0.0)], [(A = {1.0.0,2.0.0}) -> (L = 2.0.0) -> (X = 2.0.0)], [(B = 1.0.0) -> (X >= 1.0.0)], [(C = 1.0.0) -> (X = 3.0.0)], [(D = 1.0.0) -> (X >= 0.0.0)]"
    end

    it "should report failures that are caused by non-existent dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)

      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["depends_on_nosuch"]
                               ])
      er = DepSelector::ErrorReporter::SimpleTreeTraverser.new
      er.give_feedback(dep_graph, solution_constraints, 0, dep_graph.package('nosuch')).should ==
        "Unable to satisfy constraints on package nosuch, which does not exist, due to solution constraint (depends_on_nosuch >= 0.0.0). Solution constraints that may result in a constraint on nosuch: [(depends_on_nosuch = 1.0.0) -> (nosuch = 2.0.0)]"
    end

    it "should report failures that are caused by non-existent transitive dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)

      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["transitive_dep_on_nosuch"]
                               ])
      er = DepSelector::ErrorReporter::SimpleTreeTraverser.new
      er.give_feedback(dep_graph, solution_constraints, 0, dep_graph.package('nosuch')).should ==
        "Unable to satisfy constraints on package nosuch, which does not exist, due to solution constraint (transitive_dep_on_nosuch >= 0.0.0). Solution constraints that may result in a constraint on nosuch: [(transitive_dep_on_nosuch = 1.0.0) -> (depends_on_nosuch = 1.0.0) -> (nosuch = 2.0.0)]"
    end

    it "should not report non-existent cookbooks when they are not deemed to be the most constrained package" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, transitive_deps_1)
      setup_constraint(dep_graph, dependency_on_non_existent_package)

      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["X", "> 1.0.0"],
                                ["D"]
                               ])
      er = DepSelector::ErrorReporter::SimpleTreeTraverser.new
      er.give_feedback(dep_graph, solution_constraints, 1, dep_graph.package('X')).should ==
        "Unable to satisfy constraints on package X due to solution constraint (D >= 0.0.0). Solution constraints that may result in a constraint on X: [(X > 1.0.0)], [(D = 1.0.0) -> (A = 2.0.0) -> (X = 2.0.0)], [(D = 1.0.0) -> (X = 1.0.0)]"
    end

  end

  describe "collapse" do

    it "should collapse two neighbors that have only one difference in the path" do
      pending
    end

    it "should not collapse neighbors that are only different at the constraint on the target package" do
      pending
    end
    
  end

end
