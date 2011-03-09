#
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Mark Anderson (<mark@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

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
    version_text = package.densely_packed_versions.sorted_elements[package_version]
    puts "#{package.name} @ #{version_text} (#{package_id} @ #{package_version})"
  end
end

def check_solution(problem, pkg_name_to_id, dep_graph, expected_solution)
  if (problem.nil?)
    expected_solution.should be_nil
    return
  end

  passed = true;
  dep_graph.each_package do |package|
    package_id = pkg_name_to_id[package.name]
    package_version = Dep_gecode.GetPackageVersion(problem,package_id)
    version_text = package.densely_packed_versions.sorted_elements[package_version]
    expected_version = expected_solution.nil? ? "NA" : expected_solution[package.name]
    if (expected_version == "disabled") 
      Dep_gecode.GetPackageDisabledState(problem,package_id).should be_true
    else 
      version_text.to_s.should == expected_version.to_s
    end
  end
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
    Dep_gecode.GetPackageMax(problem,packageId).should == 2
    Dep_gecode.GetPackageMin(problem,packageId).should == 0
    Dep_gecode.VersionProblemSize(problem).should == 2
    Dep_gecode.VersionProblemPackageCount(problem).should == 1
    packageId = Dep_gecode.AddPackage(problem, 1, 6, 8)
    packageId.should == 1
    Dep_gecode.GetPackageVersion(problem, packageId).should == -(2**31)
    Dep_gecode.GetPackageMax(problem,packageId).should == 6
    Dep_gecode.GetPackageMin(problem,packageId).should == 1
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
    # solution constraints: [A,(B=0)], which is satisfiable as A=1, B=0
    solution_constraints = [
                            ["A"],
                            ["B", "= 1.0.0"]
                           ]
    setup_soln_constraints_for_dep_gecode(solution_constraints, @problem, @pkg_name_to_id, @dep_graph)

    # solve and interrogate problem
    new_problem = Dep_gecode.Solve(@problem)

#    print_human_readable_solution(new_problem, @pkg_name_to_id, @dep_graph)
    check_solution(new_problem, @pkg_name_to_id, @dep_graph, 
                   {'A'=>'2.0.0', 'B'=>'1.0.0', 'C'=>'1.0.0'})

    Dep_gecode.VersionProblemDestroy(@problem);
    Dep_gecode.VersionProblemDestroy(new_problem);

    # TODO: check problem's bindings
  end

   it "fails to solve a simple, unsatisfiable set of constraints" do
    # solution constraints: [(A=1.0.0),(B=1.0.0)], which is not satisfiable
    solution_constraints = [
                            ["A", "= 1.0.0"],
                            ["B", "= 1.0.0"]
                           ]
    setup_soln_constraints_for_dep_gecode(solution_constraints, @problem, @pkg_name_to_id, @dep_graph)

    # solve and interrogate problem
    new_problem = Dep_gecode.Solve(@problem)

    new_problem.should_not == nil

    Dep_gecode.VersionProblemDump(new_problem)

    check_solution(new_problem, @pkg_name_to_id, @dep_graph, 
                   {'A'=>'1.0.0', 'B'=>'disabled', 'C'=>'1.0.0'}
                   )

    Dep_gecode.VersionProblemDestroy(@problem);
  end

  # Friendlier, more abstracted tests
  # it VersionConstraints::SimpleProblem_2_insoluble[:desc] do
  #   problem_system = VersionConstraints::SimpleProblem_2_insoluble
   
  #   setup_soln_constraints_for_dep_gecode(problem_system[:runlist_constraint], @problem, @pkg_name_to_id, @dep_graph)

  #   # solve and interrogate problem
  #   new_problem = Dep_gecode.Solve(@problem)
  #   check_solution(new_problem, @pkg_name_to_id, @dep_graph, problem_system[:solution]).should == true
  #   Dep_gecode.VersionProblemDestroy(@problem);
  # end

  it VersionConstraints::SimpleProblem_3_soluble[:desc] do
      @problem_system = VersionConstraints::SimpleProblem_3_soluble
      @problem, @dep_graph, @pkg_name_to_id = setup_problem_for_dep_gecode(@problem_system[:version_constraint])

    setup_soln_constraints_for_dep_gecode(@problem_system[:runlist_constraint], @problem, @pkg_name_to_id, @dep_graph)

    # solve and interrogate problem
    new_problem = Dep_gecode.Solve(@problem)
    check_solution(new_problem, @pkg_name_to_id, @dep_graph, @problem_system[:solution])
    Dep_gecode.VersionProblemDestroy(@problem);
  end

   it "should prefer to disable suspicious packages" do
    # Note: this test is a lower-level version of the test in
    # selector_spec titled "should indicate that the problematic
    # package is the dependency that is constrained to no versions"
    problem = Dep_gecode.VersionProblemCreate(11)

    # setup dep graph
    Dep_gecode.AddPackage(problem, -1, 0, 0);
    Dep_gecode.AddPackage(problem, -1, 1, 0);
    Dep_gecode.AddPackage(problem, -1, 0, 0);
    Dep_gecode.AddPackage(problem, -1, 1, 0);
    Dep_gecode.AddPackage(problem, -1, 0, 0);
    Dep_gecode.AddPackage(problem, -1, 0, 0);
    Dep_gecode.AddPackage(problem, -1, 2, 0);
    Dep_gecode.AddPackage(problem, -1, 0, 0);
    Dep_gecode.AddPackage(problem, -1, 0, 0);
    Dep_gecode.AddPackage(problem, -1, -1, 0);
    Dep_gecode.AddPackage(problem,  0, 0, 0);
    Dep_gecode.AddVersionConstraint(problem, 0, 0, 1, 0, 1);
    Dep_gecode.AddVersionConstraint(problem, 2, 0, 1, 0, 0);
    Dep_gecode.AddVersionConstraint(problem, 1, 0, 3, 0, 1);
    Dep_gecode.AddVersionConstraint(problem, 1, 0, 4, 0, 0);
    Dep_gecode.AddVersionConstraint(problem, 1, 1, 3, 1, 1);
    Dep_gecode.AddVersionConstraint(problem, 1, 1, 5, 0, 0);
    Dep_gecode.AddVersionConstraint(problem, 7, 0, 3, -2, -2);
    Dep_gecode.AddVersionConstraint(problem, 8, 0, 9, -2, -2);

    # hint suspicious packages
    Dep_gecode.MarkPackageSuspicious(problem, 3)
    Dep_gecode.MarkPackageSuspicious(problem, 9)

    # add solution constraints
    Dep_gecode.AddVersionConstraint(problem, 10, 0, 7, 0, 0);

    soln = Dep_gecode.Solve(problem)

    # check that disabled packages are correct
    expected_disabled_packages = [false, false, false, true, false, false, false, false, false, false, false].inject({}) do |acc, is_disabled|
      acc["id #{acc.size}"] = is_disabled
      acc
    end
    observed_disabled_packages = 0.upto(10).inject({}) do |acc, package_id|
      acc["id #{package_id}"] = Dep_gecode.GetPackageDisabledState(soln, package_id)
      acc
    end
    observed_disabled_packages.should == expected_disabled_packages
  end
 
  describe "maximization of latestness of solution constraints" do
    before do
      # setup dep graph
      @problem = Dep_gecode.VersionProblemCreate(4)
      @pkg_a = Dep_gecode.AddPackage(@problem, -1, 1, 0);
      @pkg_b = Dep_gecode.AddPackage(@problem, -1, 1, 0);
      @pkg_c = Dep_gecode.AddPackage(@problem, -1, 1, 0);
      soln_constraints = Dep_gecode.AddPackage(@problem,  0, 0, 0);

      Dep_gecode.AddVersionConstraint(@problem, @pkg_a, 1, @pkg_b, 0, 0);
      Dep_gecode.AddVersionConstraint(@problem, @pkg_a, 1, @pkg_c, 0, 0);

      Dep_gecode.AddVersionConstraint(@problem, soln_constraints, 0, @pkg_a, 0, 1);
      Dep_gecode.AddVersionConstraint(@problem, soln_constraints, 0, @pkg_b, 0, 1);
      Dep_gecode.AddVersionConstraint(@problem, soln_constraints, 0, @pkg_c, 0, 1);
    end

    it "should maximize latestness of solution constraints not marked with MarkPackagePreferredToBeAtLatest" do
      Dep_gecode.MarkPackagePreferredToBeAtLatest(@problem, @pkg_a, 10);

      soln = Dep_gecode.Solve(@problem)
      soln.should_not == nil
      
      Dep_gecode.VersionProblemDump(soln)
      
      # since we haven't indicated that a, b, and c should be
      # preferred to be latest and a was added first, it should find a
      # satisfiable solution at a=1, b=0, c=0
      Dep_gecode.GetPackageVersion(soln, @pkg_a).should == 1
      Dep_gecode.GetPackageVersion(soln, @pkg_b).should == 0
      Dep_gecode.GetPackageVersion(soln, @pkg_c).should == 0
    end
    it "Should select lastest if we don't mark any at all" do

      soln = Dep_gecode.Solve(@problem)
      soln.should_not == nil
      
      Dep_gecode.VersionProblemDump(soln)
      
      # since we haven't indicated that a, b, and c should be
      # preferred to be latest and a was added first, it should find a
      # satisfiable solution at a=1, b=0, c=0
      Dep_gecode.GetPackageVersion(soln, @pkg_a).should == 0
      Dep_gecode.GetPackageVersion(soln, @pkg_b).should == 1
      Dep_gecode.GetPackageVersion(soln, @pkg_c).should == 1
    end

    # Note: this is the actual test of latestness maximization
    it "If everything is marked with MarkPackagePreferredToBeAtLatest should act the same as if nothing were due to the default latestness objective function" do
      Dep_gecode.MarkPackagePreferredToBeAtLatest(@problem, @pkg_a, 1);
      Dep_gecode.MarkPackagePreferredToBeAtLatest(@problem, @pkg_b, 1);
      Dep_gecode.MarkPackagePreferredToBeAtLatest(@problem, @pkg_c, 1);

      # now, mark a, b, and c as preferred to be at latest and observe
      # that a=0, b=1, and c=1 is chosen
      soln = Dep_gecode.Solve(@problem)
      soln.should_not == nil

      Dep_gecode.VersionProblemDump(soln)
      Dep_gecode.GetPackageVersion(soln, @pkg_a).should == 0
      Dep_gecode.GetPackageVersion(soln, @pkg_b).should == 1
      Dep_gecode.GetPackageVersion(soln, @pkg_c).should == 1
    end
  end

end


