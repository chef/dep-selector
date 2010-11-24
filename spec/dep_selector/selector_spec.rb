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

def create_objective_function(dep_graph, current_versions)
  lambda do |soln|
    # Note: We probably have to filter out the unnecessary dependencies
    # that are nonetheless bound here so that we're not unjustly
    # punishing the solution under consideration for appearing to change
    # packages that will actually just get removed.
    edit_distance = current_versions.inject(0) do |acc, curr_version|
      # TODO [cw,2010/11/21]: This edit distance only increases when a
      # package that is currently deployed is changed, not when a new
      # dependency is added. I think there is an argument to be made
      # that also including new packages is worthy of an edit distance
      # bump, since the interpretation can be that any difference in
      # code that is run (not just changing existing code) could be
      # considered "infrastructure instability". This needs to be
      # considered.
      pkg_name, curr_version = curr_version
      if soln.has_key?(pkg_name)
        putative_version = soln[pkg_name]
        puts "#{pkg_name} going from #{curr_version} to #{putative_version}"
        acc -= 1 unless putative_version == curr_version
      end
      acc
    end
  end
end


describe DepSelector::Selector do

  describe "solves without an objective function" do

    it "a simple set of constraints and does not include unnecessary assignments" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
         {:name => "B", :version_constraint => DepSelector::VersionConstraint.new("= 1.0.0")}
        ]
      soln = selector.find_solution(solution_constraints)
      # TODO [cw,2010/11/24]: uncomment this assertion when
      # unnecessary assignments are removed
#      soln.length.should == 2
      soln[0].to_hash.should == { :package_name => "A", :version => "2.0.0"}
      soln[1].to_hash.should == { :package_name => "B", :version => "1.0.0"}
    end

    it "a simple set of constraints and does not include unnecessary assignments" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
         {:name => "B", :version_constraint => DepSelector::VersionConstraint.new("= 2.0.0")}
        ]
      soln = selector.find_solution(solution_constraints)
      # TODO [cw,2010/11/24]: uncomment this assertion when
      # unnecessary assignments are removed
#      soln.length.should == 2
      soln[0].to_hash.should == { :package_name => "A", :version => "1.0.0"}
      soln[1].to_hash.should == { :package_name => "B", :version => "2.0.0"}
    end

    it "and indicates which solution constraint makes the system unsatisfiable if there is no solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint_2)
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

    it "can solve a moderately complex system with a set of current versions" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints = 
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
        ]
      soln = selector.find_solution(solution_constraints)

      soln[0].to_hash.should == { :package_name => "A", :version => "1.0.0"}
      soln[1].to_hash.should == { :package_name => "B", :version => "2.0.0"}
      soln[2].to_hash.should == { :package_name => "C", :version => "4.0.0"}
      soln[3].to_hash.should == { :package_name => "D", :version => "4.0.0"}
    end

    # TODO: more complex tests

  end

  describe "solves with an objective function" do

    it "a simple set of constraints and does not include unnecessary assignments" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new}
        ]

      # optimize for one configuration
      current_versions = { "A" => "1.0.0", "B" => "2.0.0"}
      soln = selector.find_solution(solution_constraints) do |soln|
        create_objective_function(dep_graph, current_versions).call(soln)
      end
      # TODO [cw,2010/11/24]: uncomment this assertion when
      # unnecessary assignments are removed
#      soln.length.should == 2
      soln[0].to_hash.should == { :package_name => "A", :version => "1.0.0"}
      soln[1].to_hash.should == { :package_name => "B", :version => "2.0.0"}

      # now optimize for another
      current_versions = { "A" => "2.0.0", "B" => "1.0.0"}
      soln = selector.find_solution(solution_constraints) do |soln|
        create_objective_function(dep_graph, current_versions).call(soln)
      end
      # TODO [cw,2010/11/24]: uncomment this assertion when
      # unnecessary assignments are removed
#      soln.length.should == 2
      soln[0].to_hash.should == { :package_name => "A", :version => "2.0.0"}
      soln[1].to_hash.should == { :package_name => "B", :version => "1.0.0"}

    end

    it "can solve a moderately complex system with a set of current versions" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints = 
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
        ]
      current_versions = { "A" => "1.0.0", "B" => "2.0.0"}
      solution = selector.find_solution(solution_constraints) do |soln|
        create_objective_function(dep_graph, current_versions).call(soln)
      end
      # TODO [cw,2010/11/24]: uncomment this assertion when
      # unnecessary assignments are removed
#      solution.length.should == 2

      solution[0].to_hash.should == { :package_name => "A", :version => "1.0.0"}
      solution[1].to_hash.should == { :package_name => "B", :version => "2.0.0"}
      solution[2].to_hash.should == { :package_name => "C", :version => "4.0.0"}
      solution[3].to_hash.should == { :package_name => "D", :version => "4.0.0"}
    end

    it "and indicates which solution constraint makes the system unsatisfiable if there is no solution" do
      pending "TODO"
    end

    # TODO: more complex tests

  end

end
