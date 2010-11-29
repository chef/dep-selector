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

def compute_edit_distance(soln, current_versions)
  current_versions.inject(0) do |acc, curr_version|
    # TODO [cw,2010/11/21]: This edit distance only increases when a
    # package that is currently deployed is changed, not when a new
    # dependency is added. I think there is an argument to be made
    # that also including new packages is worthy of an edit distance
    # bump, since the interpretation can be that any difference in
    # code that is run (not just changing existing code) could be
    # considered "infrastructure instability". And by that same
    # reasoning, perhaps removal of packages should increase the edit
    # distance, as well. This needs to be considered.
    pkg_name, curr_version = curr_version
    if soln.has_key?(pkg_name)
      putative_version = soln[pkg_name]
      puts "Package #{pkg_name}: current = #{curr_version}, soln assignmen = #{putative_version}#{putative_version == curr_version ? "" : " (changing)"}"
      acc -= 1 unless putative_version == curr_version
      end
    acc
  end
end

class Array
  def > (b)
    (self <=> b) > 0
  end
end

def compute_latest_version_count(soln, latest_versions)
  latest_versions.inject(0) do |acc, version|
    pkg_name, latest_version = version
    if soln.has_key?(pkg_name) 
      trial_version = soln[pkg_name]
      puts "Package #{pkg_name}: latest = #{latest_version}, soln assignment = #{trial_version}#{trial_version == latest_version ? "" : " (NOT latest)"}"
      acc -= 1 unless trial_version == latest_version
    end
    acc
  end
end

def create_latest_version_objective_function(dep_graph)
  # determine latest versions from dep_graph
  latest_versions = {}
  dep_graph.each_package do |pkg|
    latest_version_id =  pkg.densely_packed_versions.range.last
#    pp :name=>pkg.name, :latest_version_id=>latest_version_id, :latest_version_string=>pkg.densely_packed_versions.sorted_triples[latest_version_id]
    latest_versions[pkg.name] = pkg.densely_packed_versions.sorted_triples[latest_version_id]
  end
  
  lambda do |soln|
    compute_latest_version_count(soln, latest_versions)
  end
end

def create_minimum_churn_objective_function(dep_graph, current_versions)
  lambda do |soln|
    compute_edit_distance(soln, current_versions)
  end
end

# This method composes the latest_version and minimum_churn objective
# functions.
def create_latest_version_minimum_churn_objective_function(dep_graph, current_versions)
  latest_version_objective_function = create_latest_version_objective_function(dep_graph)
  minimum_churn_objective_function = create_minimum_churn_objective_function(dep_graph, current_versions)
  lambda do |soln|
    latest_weight = latest_version_objective_function.call(soln)
    churn_weight = minimum_churn_objective_function.call(soln)
    x = [latest_weight, churn_weight]    
    pp :obj_fun => x
    x
  end
end


describe DepSelector::Selector do

  describe "solves without an objective function" do

    it "a simple set of constraints and includes transitive dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
         {:name => "B", :version_constraint => DepSelector::VersionConstraint.new("= 1.0.0")}
        ]
      soln = selector.find_solution(solution_constraints)

      soln.should == {
        "A" => "2.0.0",
        "B" => "1.0.0",
        "C" => "1.0.0"
      }
    end

    it "a simple set of constraints and doesn't include unnecessary dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
         {:name => "B", :version_constraint => DepSelector::VersionConstraint.new("= 2.0.0")}
        ]
      soln = selector.find_solution(solution_constraints)

      soln.should == {
        "A" => "1.0.0",
        "B" => "2.0.0"
      }
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

      soln.should == {
        "A" => "1.0.0",
        "B" => "2.0.0"
      }
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

      soln.should == {
        "A" => "1.0.0",
        "B" => "2.0.0",
        "C" => "4.0.0",
        "D" => "4.0.0"
      }
    end

    it "can solve a moderately complex system with a larger set of current versions" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints = 
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
         {:name => "C", :version_constraint => DepSelector::VersionConstraint.new},
        ]
      soln = selector.find_solution(solution_constraints)

      soln.should == {
        "A" => "1.0.0",
        "B" => "2.0.0",
        "C" => "4.0.0",
        "D" => "4.0.0"
      }
    end

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
      objective_function = create_minimum_churn_objective_function(dep_graph, current_versions)

      soln = selector.find_solution(solution_constraints) do |soln|
        objective_function.call(soln)
      end

      soln.should == {
        "A" => "1.0.0",
        "B" => "2.0.0"
      }

      # now optimize for another
      current_versions = { "A" => "2.0.0", "B" => "1.0.0" }
      objective_function = create_minimum_churn_objective_function(dep_graph, current_versions)

      soln = selector.find_solution(solution_constraints) do |soln|
        objective_function.call(soln)
      end

      soln.should == {
        "A" => "2.0.0",
        "B" => "1.0.0",
        "C" => "1.0.0"
      }
    end

    it "a simple set of constraints with ranges, selects the latest transitive dependencies, and does not include unnecessary assignments" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint_3)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints = 
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
        ]
      objective_function = create_latest_version_objective_function(dep_graph)
      soln = selector.find_solution(solution_constraints) do |soln|
        objective_function.call(soln)
      end

      soln.should == {
        "A" => "1.0.0",
        "B" => "2.0.0"
      }
    end

    it "a moderately complex system with a set of current versions" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints = 
        [
         {:name => "A", :version_constraint => DepSelector::VersionConstraint.new},
        ]
      current_versions = { "A" => "1.0.0", "B" => "2.0.0"}
      bottom = [DepSelector::ObjectiveFunction::MinusInfinity, DepSelector::ObjectiveFunction::MinusInfinity] 
      pp :current_versions=>current_versions, :bottom=>bottom
      objective_function = create_latest_version_minimum_churn_objective_function(dep_graph, current_versions)
      soln = selector.find_solution(solution_constraints,bottom) do |soln|
        objective_function.call(soln)
      end

      soln.should == {
        "A" => "1.0.0",
        "B" => "2.0.0",
        "C" => "4.0.0",
        "D" => "4.0.0"
      }
    end

    it "and indicates which solution constraint makes the system unsatisfiable if there is no solution" do
      pending "TODO"
    end

  end

end
