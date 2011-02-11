require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'ext/gecode/dep_gecode'
require 'version_constraints'

# so that we can use test data that's already written in other tests,
# we're accepting the same format but adapting it for our C++ wrapper
# for gecode, which is exposed in Dep_gecode
def setup_problem_for_dep_gecode(relationships)

#  pp :relationships=>relationships
  
  dep_graph = DepSelector::DependencyGraph.new
  setup_constraint(dep_graph, relationships)

  dep_gecode_packages = {}
  problem = Dep_gecode.VersionProblemCreate(dep_graph.packages.size+1) # extra for runlist meta package

  # all packages must be created before dependencies using them can be created
  dep_graph.each_package do |package|
    versions = package.densely_packed_versions.range
    dep_gecode_packages[package.name] = Dep_gecode.AddPackage(problem, versions.min, versions.max, versions.max)
  end

  # register dependencies of each package version
  dep_graph.each_package do |package|
    pkg_id = dep_gecode_packages[package.name]
    package.versions.each do |pkg_ver|
      pkg_ver_id = package.densely_packed_versions.index(pkg_ver.version)
      pkg_ver.dependencies.each do |dep|
        matching_ver_ids = dep.package.densely_packed_versions[dep.constraint]
        Dep_gecode.AddVersionConstraint(problem,
                                        pkg_id,
                                        pkg_ver_id,
                                        dep_gecode_packages[dep.package.name],
                                        matching_ver_ids.min,
                                        matching_ver_ids.max)
      end
    end
  end

  [ problem, dep_graph, dep_gecode_packages ]
end

def setup_soln_constraints_for_dep_gecode(soln_constraints, problem, pkg_name_to_id, dep_graph)
  # metapackage is a "ghost" package whose dependencies are the
  # solution constraints; thereby forcing packages to be appropriately
  # constrained
  metapkg = Dep_gecode.AddPackage(problem, 0, 0, 0)

  # we go through the expense of calling setup_soln_constraints,
  # because ultimately we're after the densely-packed ids of each
  # package and constraint, which we get for free by using the
  # dep_graph.
  setup_soln_constraints(dep_graph, soln_constraints).each do |soln_constraint|
    matching_ver_ids = soln_constraint.package.densely_packed_versions[soln_constraint.constraint]
    Dep_gecode.AddVersionConstraint(problem,
                                    metapkg,
                                    0,
                                    pkg_name_to_id[soln_constraint.package.name],
                                    matching_ver_ids.min,
                                    matching_ver_ids.max)
  end
end

def print_human_readable_solution(problem, pkg_name_to_id, dep_graph)
  dep_graph.each_package do |package|  
    package_id = pkg_name_to_id[package.name]
    package_version = Dep_gecode.GetPackageVersion(problem,package_id)
    version_text = package.densely_packed_versions.sorted_triples[package_version]
    puts "#{package.name} @ #{version_text} (#{package_id} @ #{package_version})"
  end
end

def print_check_solution(problem, pkg_name_to_id, dep_graph, expected_solution)
  puts "Checking solution"
  if (problem.nil?)
    return expected_solution.nil?
  end

  passed = true;
  dep_graph.each_package do |package|
    package_id = pkg_name_to_id[package.name]
    package_version = Dep_gecode.GetPackageVersion(problem,package_id)
    version_text = package.densely_packed_versions.sorted_triples[package_version]
    expected_version = expected_solution.nil? ? "NA" : expected_solution[package.name]
    pass = (version_text.to_s==expected_version.to_s)
    puts "#{package.name} @ '#{version_text}' (#{package_id} @ #{package_version}) Expected '#{expected_version}' #{pass ? 'OK' : 'FAIL'}"
    passed &= pass
  end
  return passed
end


def print_bindings(problem, vars)
  vars.each do |var|
    Dep_gecode.VersionProblemPrintPackageVar(problem, var)
    puts "\n"
  end
end

describe Dep_gecode do
  
  it "Can be created and destroyed" do
    problem = Dep_gecode.VersionProblemCreate(1) 
    Dep_gecode.VersionProblemDestroy(problem)
  end

  it "Can be created, and have packages added to it" do
    problem = Dep_gecode.VersionProblemCreate(2) 
    Dep_gecode.VersionProblemSize(problem).should == 2
    Dep_gecode.VersionProblemPackageCount(problem).should == 0
    packageId = Dep_gecode.AddPackage(problem, 0, 2, 8)
    packageId.should == 0
    Dep_gecode.GetPackageVersion(problem, packageId).should == -(2**31)
    Dep_gecode.GetAFC(problem,packageId).should == 0
    Dep_gecode.GetMax(problem,packageId).should == 2
    Dep_gecode.GetMin(problem,packageId).should == 0
    Dep_gecode.VersionProblemSize(problem).should == 2
    Dep_gecode.VersionProblemPackageCount(problem).should == 1
    packageId = Dep_gecode.AddPackage(problem, 1, 6, 8)
    packageId.should == 1
    Dep_gecode.GetPackageVersion(problem, packageId).should == -(2**31)
    Dep_gecode.GetAFC(problem,packageId).should == 0
    Dep_gecode.GetMax(problem,packageId).should == 6
    Dep_gecode.GetMin(problem,packageId).should == 1
    Dep_gecode.VersionProblemSize(problem).should == 2
    Dep_gecode.VersionProblemPackageCount(problem).should == 2
    Dep_gecode.VersionProblemDestroy(problem)
  end

end

describe Dep_gecode do
  before do
    @problem, @dep_graph, @pkg_name_to_id = setup_problem_for_dep_gecode(VersionConstraints::Simple_cookbook_version_constraint)
  end

  it "solves a simple set of constraints" do
    puts "before adding soln constraints"
    print_bindings(@problem, [*(0..2)])

    # solution constraints: [A,(B=0)], which is satisfiable as A=1, B=0
    solution_constraints = [
                            ["A"],
                            ["B", "= 1.0.0"]
                           ]
    setup_soln_constraints_for_dep_gecode(solution_constraints, @problem, @pkg_name_to_id, @dep_graph)

    puts "after adding soln constraints"
    print_bindings(@problem, [*(0..3)])

    # solve and interrogate problem
    puts "Solving"
    new_problem = Dep_gecode.Solve(@problem)
    puts "Solved"

    puts "after solving"
    print_bindings(new_problem, [*(0..3)])
    puts "HR solution"
#    print_human_readable_solution(new_problem, @pkg_name_to_id, @dep_graph)
    print_check_solution(new_problem, @pkg_name_to_id, @dep_graph, 
                         {'A'=>'2.0.0', 'B'=>'1.0.0', 'C'=>'1.0.0'}).should == true

    Dep_gecode.VersionProblemDestroy(@problem);
    Dep_gecode.VersionProblemDestroy(new_problem);

    # TODO: check problem's bindings
  end

  it "fails to solve a simple, unsatisfiable set of constraints" do
    puts "before adding soln constraints"
    print_bindings(@problem, [*(0..2)])
    
    # solution constraints: [(A=1.0.0),(B=1.0.0)], which is not satisfiable
    solution_constraints = [
                            ["A", "= 1.0.0"],
                            ["B", "= 1.0.0"]
                           ]
    setup_soln_constraints_for_dep_gecode(solution_constraints, @problem, @pkg_name_to_id, @dep_graph)

    puts "after adding soln constraints"
    print_bindings(@problem, [*(0..3)])

    # solve and interrogate problem
    puts "Solving"
    new_problem = Dep_gecode.Solve(@problem)

    new_problem.should == nil

    puts "after solving"
    print_check_solution(new_problem, @pkg_name_to_id, @dep_graph, nil).should == true

    Dep_gecode.VersionProblemDestroy(@problem);

    # TODO: do appropriate interrogation
  end

  # Friendlier, more abstracted tests
  it VersionConstraints::SimpleProblem_2_insoluble[:desc] do
    problem_system = VersionConstraints::SimpleProblem_2_insoluble
    puts "before adding soln constraints"
    print_bindings(@problem, [*(0..2)])
   
    setup_soln_constraints_for_dep_gecode(problem_system[:runlist_constraint], @problem, @pkg_name_to_id, @dep_graph)

    # solve and interrogate problem
    puts "Solving"
    new_problem = Dep_gecode.Solve(@problem)
    print_check_solution(new_problem, @pkg_name_to_id, @dep_graph, problem_system[:solution]).should == true
    Dep_gecode.VersionProblemDestroy(@problem);
  end

  it VersionConstraints::SimpleProblem_3_soluble[:desc] do
    @problem_system = VersionConstraints::SimpleProblem_3_soluble
    @problem, @dep_graph, @pkg_name_to_id = setup_problem_for_dep_gecode(@problem_system[:version_constraint])
    puts "before adding soln constraints"
    print_bindings(@problem, [*(0..2)])
   
    setup_soln_constraints_for_dep_gecode(@problem_system[:runlist_constraint], @problem, @pkg_name_to_id, @dep_graph)

    # solve and interrogate problem
    puts "Solving"
    new_problem = Dep_gecode.Solve(@problem)
    print_check_solution(new_problem, @pkg_name_to_id, @dep_graph, @problem_system[:solution]).should == true
    Dep_gecode.VersionProblemDestroy(@problem);
  end


end


