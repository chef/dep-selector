require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

simple_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}},
   {"key"=>["C", "2.0.0"], "value"=>{}},
   {"key"=>["C", "3.0.0"], "value"=>{}}
  ]


def package_version(dep_graph, pkg_name, version)
  dep_graph.package(pkg_name).versions.find{|pkg_version| pkg_version.version == version}
end


describe DepSelector::Selector do

  describe "solves without an objective function" do

    it "a simple set of constraints and does not include unnecessary assignments" do
      pending "This test works, except that unnecessary packages are included in solutions (in this case, C), so once that logic filters them out, this test will work"
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
         {:name => "B", :version_constraint => DepSelector::VersionConstraint.new("= 1.0.0")}
        ]
      soln = selector.find_solution(solution_constraints)
      soln.length.should == 2
      soln[0].should == package_version(dep_graph, "A", "2.0.0")
      soln[1].should == package_version(dep_graph, "B", "1.0.0")
    end

    it "and indicates which solution constraint makes the system unsatisfiable if there is no solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
         {:name => "C", :version_constraint => DepSelector::VersionConstraint.new("= 3.0.0")}
        ]
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_constraint.should == unsatisfiable_solution_constraints.last
      end
    end

    # TODO: more complex tests

  end

  describe "solves with an objective function" do

    it "a simple set of constraints and does not include unnecessary assignments" do
      pending "TODO"
    end

    it "and indicates which solution constraint makes the system unsatisfiable if there is no solution" do
      pending "TODO"
    end

    # TODO: more complex tests

  end

end
