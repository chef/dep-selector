

require 'ext/gecode/dep_gecode'

module DepSelector
  class GecodeWrapper
    attr_reader :gecode_problem

    # This insures that we properly deallocate the c++ class at the heart of dep_gecode.
    # modeled after http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def initialize(package_or_package_count)
      if (package_or_package_count.is_a?(Numeric))
        @gecode_problem = Dep_gecode.VersionProblemCreate(package_or_package_count)
      else
        @gecode_problem = package_or_package_count;
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
      Dep_gecode.AddVersionConstraint(gecode_problem, package_id, version, dependent_package_id, min_dependent_version, max_dependent_version)
    end
    def get_package_version(package_id)
      Dep_gecode.GetPackageVersion(gecode_problem, package_id)
    end
    def get_package_afc(package_id) 
      Dep_gecode.GetAFC(gecode_problem, package_id)
    end
    def get_package_max(package_id) 
      Dep_gecode.GetMax(gecode_problem, package_id)
    end
    def get_package_min(package_id) 
      Dep_gecode.GetMin(gecode_problem, package_id)
    end
    def dump() 
      Dep_gecode.VersionProblemDump(gecode_problem)
    end
    def dump_package_var(package_id)
      Dep_gecode.VersionProblemPrintPackageVar(gecode_problem, package_id)
    end

    def solve()
      GecodeWrapper.new(Dep_gecode.Solve(gecode_problem))
    end

  end
end
