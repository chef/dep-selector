require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

require 'pp'

simple_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}}]


complex_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
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
   {"key"=>["D", "4.0.0"], "value"=>{}},
]

describe DepSelector::DependencyGraph do
  it "can create a package named foo" do
    dep_graph = DepSelector::DependencyGraph.new
    pkg = dep_graph.package("A")
    pkg.name.should == "A"
  end
  
  it "can solve a simple system with one set of current versions" do
    pending "Elimination"
    dep_graph = DepSelector::DependencyGraph.new
    setup_constraint(dep_graph, simple_cookbook_version_constraint)
    dep_graph.generate_gecode_constraints
    run_list = [["A", nil]]
    add_run_list(dep_graph, run_list)
    current_versions = {"A" => "2.0.0", "B" => "1.0.0"}
    objective_function = init_objective_function(dep_graph, run_list, current_versions)
    dep_graph.each_solution do |soln|
      objective_function.consider(soln)
    end
    pp objective_function.best_solution
    dump_result(dep_graph, objective_function)
    verify_result(dep_graph, objective_function, {'A'=>'2.0.0', 'B'=>'1.0.0', 'C'=>'1.0.0'} )
  end

  it "can solve a simple system with another set of current versions" do
    pending "Elimination"
    dep_graph = DepSelector::DependencyGraph.new
    setup_constraint(dep_graph, simple_cookbook_version_constraint)
    dep_graph.generate_gecode_constraints
    run_list = [["A", nil]]
    add_run_list(dep_graph, run_list)
    current_versions = {"A" => "1.0.0", "B" => "2.0.0"}
    objective_function = init_objective_function(dep_graph, run_list, current_versions)
    dep_graph.each_solution do |soln|
      objective_function.consider(soln)
    end
    pp objective_function.best_solution
    dump_result(dep_graph, objective_function)
    verify_result(dep_graph, objective_function, {'A'=>'1.0.0', 'B'=>'2.0.0', 'C'=>'1.0.0'} )
  end

  it "can handle failing to solve a simple system with impossible constraints" do
    pending "Impossible constraint work done"
    dep_graph = DepSelector::DependencyGraph.new
    setup_constraint(dep_graph, simple_cookbook_version_constraint)
    dep_graph.generate_gecode_constraints
    run_list = [["A", "1.0.0"], ["B", "1.0.0"]]
    add_run_list(dep_graph, run_list)
    current_versions = {"A" => "1.0.0", "B" => "2.0.0"}
    objective_function = init_objective_function(dep_graph, run_list, current_versions)
    dep_graph.each_solution do |soln|
      objective_function.consider(soln)
    end
    pp objective_function.best_solution
    dump_result(dep_graph, objective_function)
    verify_result(dep_graph, objective_function, {'A'=>'1.0.0', 'B'=>'2.0.0', 'C'=>'1.0.0'} )
  end

  it "can solve a more complex system with a set of current versions" do
    pending "Elimination"
    dep_graph = DepSelector::DependencyGraph.new
    setup_constraint(dep_graph, complex_cookbook_version_constraint)
    dep_graph.generate_gecode_constraints
    run_list = [["A", nil]]
    add_run_list(dep_graph, run_list)
    current_versions = {"A" => "1.0.0", "B" => "2.0.0"}
    objective_function = init_objective_function(dep_graph, run_list, current_versions)
    dep_graph.each_solution do |soln|
      objective_function.consider(soln)
    end
    pp objective_function.best_solution
    dump_result(dep_graph, objective_function)
    # TODO 2010-11-23 (mark) should check that unneeded deps are not defined
    verify_result(dep_graph, objective_function, {'A'=>'1.0.0', 'B'=>'2.0.0'} )
  end

  it "can solve a more complex system with a set of current versions and a longer runlist" do
#    pending "Fixes for densely packed triple"
    pending "Elimination"
    dep_graph = DepSelector::DependencyGraph.new
    setup_constraint(dep_graph, complex_cookbook_version_constraint)
    run_list = [["A", nil], ["B", nil], ["C",nil], ["D", nil] ]
    add_run_list(dep_graph, run_list)
    current_versions = {"A" => "1.0.0", "B" => "2.0.0"}
    objective_function = init_objective_function(dep_graph, run_list, current_versions)
    dep_graph.each_solution do |soln|
      objective_function.consider(soln)
    end
    pp objective_function.best_solution
    dump_result(dep_graph, objective_function)
    # TODO 2010-11-23 (mark) should check that unneeded deps are not defined
    verify_result(dep_graph, objective_function, {'A'=>'1.0.0', 'B'=>'2.0.0', 'C'=>'4.0.0', 'D'=>'4.0.0'} )
  end

  it "#clone should perform a deep copy" do
    pending "Elimination"
    dg1 = DepSelector::DependencyGraph.new
    dg2 = dg1.clone
    dg2.package("should only exist in dg2")
    dg1.packages.should be_empty

    dg1.package("foo")
    dg2 = dg1.clone
    dg2.packages.should have_key("foo")
    dg2.package("foo").add_version("1.0.0")
    dg1.package("foo").versions.should be_empty
  end
end
