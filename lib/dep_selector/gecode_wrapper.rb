require "dep_gecode"
require 'dep_selector/exceptions'

module DepSelector
  class GecodeWrapper
    attr_reader :gecode_problem

    # This insures that we properly deallocate the c++ class at the heart of dep_gecode.
    # modeled after http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def initialize(problem_or_package_count)
      if (problem_or_package_count.is_a?(Numeric))
        @gecode_problem = Dep_gecode.VersionProblemCreate(problem_or_package_count)
      else
        @gecode_problem = problem_or_package_count
      end
      ObjectSpace.define_finalizer(self, self.class.finalize(@gecode_problem))
    end
    def self.finalize(gecode_problem)
      proc { Dep_gecode.VersionProblemDestroy(gecode_problem) }
    end
    
    def size()
      Dep_gecode.VersionProblemSize(gecode_problem)
    end
    def package_count()
      Dep_gecode.VersionProblemPackageCount(gecode_problem)
    end
    def add_package(min, max, current_version)
      Dep_gecode.AddPackage(gecode_problem, min, max, current_version)
    end
    def add_version_constraint(package_id, version, dependent_package_id, min_dependent_version, max_dependent_version)
      # Valid package versions are between -1 and its max (-1 means
      # don't care, meaning it doesn't need to be assigned). To
      # indicate constraints that match no versions, -2 is used, since
      # it's not a valid assignment of the variable; thus, any branch
      # that assigns -2 will fail.
      #
      # This mechanism is also used when a dependent package has no
      # versions, which only happens if the dependency's package is
      # auto-vivified when creating the parent PackageVersion's
      # dependency but with no corresponding set of PackageVersions
      # (i.e. it's an invalid deendency, because it does not exist in
      # the dependency graph). Again, we won't abort immediately, but
      # we'll add a constraint to the package that makes exploring
      # that portion of the solution space unsatisfiable. Thus it is
      # impossible to find solutions dependent on non-existent
      # packages.
      min = min_dependent_version || -2
      max = max_dependent_version || -2
      Dep_gecode.AddVersionConstraint(gecode_problem, package_id, version, dependent_package_id, min, max)
    end
    def get_package_version(package_id)
      Dep_gecode.GetPackageVersion(gecode_problem, package_id)
    end
    def get_package_afc(package_id) 
      Dep_gecode.GetPackageAFC(gecode_problem, package_id)
    end
    def get_package_max(package_id) 
      Dep_gecode.GetPackageMax(gecode_problem, package_id)
    end
    def get_package_min(package_id) 
      Dep_gecode.GetPackageMin(gecode_problem, package_id)
    end
    def dump() 
      Dep_gecode.VersionProblemDump(gecode_problem)
    end
    def dump_package_var(package_id)
      Dep_gecode.VersionProblemPrintPackageVar(gecode_problem, package_id)
    end

    def solve()
      solution = Dep_gecode.Solve(gecode_problem)
      # TODO: communicate solution stats here (most constrained var,
      # etc.) here. Maybe needs to be a different exception.
      raise Exceptions::NoSolutionExists.new(nil) unless solution
      GecodeWrapper.new(solution)
    end

  end
end
