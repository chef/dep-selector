require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'ext/gecode/dep_gecode'

def print_bindings(problem, vars)
  vars.each do |var|
    Dep_gecode.VersionProblemPrintPackageVar(problem, var)
    puts "\n"
  end
end

describe Dep_gecode do

  before do
    @problem = Dep_gecode.VersionProblemCreate
    # package A has versions 0, 1
    @pkg_a = Dep_gecode.AddPackage(@problem, 0, 1, 1)
    # package B has versions 0, 1
    @pkg_b = Dep_gecode.AddPackage(@problem, 0, 1, 1)
    # package C has versions 0
    @pkg_c = Dep_gecode.AddPackage(@problem, 0, 0, 0)

    # A0 depends on B1
    Dep_gecode.AddVersionConstraint(@problem, @pkg_a, 0, @pkg_b, 1, 1)

    # A1 depends on B0, C0
    Dep_gecode.AddVersionConstraint(@problem, @pkg_a, 0, @pkg_b, 0, 0)
    Dep_gecode.AddVersionConstraint(@problem, @pkg_a, 0, @pkg_c, 0, 0)
  end

  it "solves a simple set of constraints" do

    # metapackage is a "ghost" package whose dependencies are the
    # solution constraints; thereby forcing packages to be
    # appropriately constrained
    metapkg = Dep_gecode.AddPackage(@problem, 0, 0, 0)

    puts "before adding soln constraints"
    print_bindings(@problem, [@pkg_a, @pkg_b, @pkg_c, metapkg])

    # solution constraints: [A,(B=0)], which is satisfiable as A=1, B=0
    Dep_gecode.AddVersionConstraint(@problem, metapkg, 0, @pkg_a, 0, 1)
    Dep_gecode.AddVersionConstraint(@problem, metapkg, 0, @pkg_b, 0, 0)

    puts "after adding soln constraints"
    print_bindings(@problem, [@pkg_a, @pkg_b, @pkg_c, metapkg])

    # solve and interrogate problem
    Dep_gecode.Solve(@problem).should == true

    puts "after solving"
    print_bindings(@problem, [@pkg_a, @pkg_b, @pkg_c, metapkg])

    # TODO: check problem's bindings
  end

  it "fails to solve a simple, unsatisfiable set of constraints" do
    # metapackage is a "ghost" package whose dependencies are the
    # solution constraints; thereby forcing packages to be
    # appropriately constrained
    metapkg = Dep_gecode.AddPackage(@problem, 0, 0, 0)
    
    puts "before adding soln constraints"
    print_bindings(@problem, [@pkg_a, @pkg_b, @pkg_c, metapkg])

    # solution constraints: [(A=0),(B=0)], which is not satisfiable
    Dep_gecode.AddVersionConstraint(@problem, metapkg, 0, @pkg_a, 0, 0)
    Dep_gecode.AddVersionConstraint(@problem, metapkg, 0, @pkg_b, 0, 0)

    puts "after adding soln constraints"
    print_bindings(@problem, [@pkg_a, @pkg_b, @pkg_c, metapkg])

    # solve and interrogate problem
    Dep_gecode.Solve(@problem).should == false

    puts "after solving"
    print_bindings(@problem, [@pkg_a, @pkg_b, @pkg_c, metapkg])

    # TODO: do appropriate interrogation
  end

end
