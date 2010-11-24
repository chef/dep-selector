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



describe DepSelector::Selector do
  it "doesn't include unnecessary packages in the solution" do
    # TODO: implement
  end

  it "properly indicates which solution constraint makes the system unsatisfiable" do
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
end
