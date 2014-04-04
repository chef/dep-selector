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

require 'securerandom'
require 'dep_selector/dep_gecode'
require 'dep_selector/exceptions'

module DepSelector

  @dump_statistics = false

  def self.dump_statistics
    @dump_statistics
  end

  def self.dump_statistics=(dump_statistics)
    @dump_statistics = dump_statistics
  end

  class GecodeWrapper

    attr_reader :gecode_problem
    attr_reader :debug_logs_on
    DontCareConstraint = -1
    NoMatchConstraint = -2

    # This insures that we properly deallocate the c++ class at the heart of dep_gecode.
    # modeled after http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def initialize(problem_or_package_count, debug=false)
      if (problem_or_package_count.is_a?(Numeric))
        logId = SecureRandom.uuid
        dump_statistics = DepSelector.dump_statistics || debug
        @debug_logs_on = debug
        @gecode_problem = Dep_gecode.VersionProblemCreate(problem_or_package_count, dump_statistics, debug, logId)
      else
        @gecode_problem = problem_or_package_count
      end
      ObjectSpace.define_finalizer(self, self.class.finalize(@gecode_problem))
    end
    def self.finalize(gecode_problem)
      proc { Dep_gecode.VersionProblemDestroy(gecode_problem) }
    end

    def check_package_id(package_id, param_name)
      raise "Gecode #{param_name} is out of range #{package_id}" unless (package_id >= 0 && package_id < self.size())
    end

    def size()
      raise "Gecode internal failure" if gecode_problem.nil?
      Dep_gecode.VersionProblemSize(gecode_problem)
    end
    def package_count()
      raise "Gecode internal failure" if gecode_problem.nil?
      Dep_gecode.VersionProblemPackageCount(gecode_problem)
    end
    def add_package(min, max, current_version)
      raise "Gecode internal failure" if gecode_problem.nil?
      Dep_gecode.AddPackage(gecode_problem, min, max, current_version)
    end

    def add_version_constraint(package_id, version, dependent_package_id, min_dependent_version, max_dependent_version)
      raise "Gecode internal failure" if gecode_problem.nil?
      check_package_id(package_id, "package_id")
      check_package_id(dependent_package_id, "dependent_package_id")

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

      min = min_dependent_version || NoMatchConstraint
      max = max_dependent_version || NoMatchConstraint
      Dep_gecode.AddVersionConstraint(gecode_problem, package_id, version, dependent_package_id, min, max)

      # if the package was constrained to no versions, hint to the
      # solver that in the event of failure, it should prefer to
      # indicate constraints on dependent_package_id as the culprit
      if min == NoMatchConstraint && max == NoMatchConstraint
        Dep_gecode.MarkPackageSuspicious(gecode_problem, dependent_package_id)
      end
    end
    def get_package_version(package_id)
      raise "Gecode internal failure" if gecode_problem.nil?
      check_package_id(package_id, "package_id")
      Dep_gecode.GetPackageVersion(gecode_problem, package_id)
    end
    def is_package_disabled?(package_id)
      raise "Gecode internal failure" if gecode_problem.nil?
      check_package_id(package_id, "package_id")
      Dep_gecode.GetPackageDisabledState(gecode_problem, package_id);
    end

    def get_package_max(package_id)
      raise "Gecode internal failure" if gecode_problem.nil?
      check_package_id(package_id, "package_id")
      Dep_gecode.GetPackageMax(gecode_problem, package_id)
    end
    def get_package_min(package_id)
      raise "Gecode internal failure" if gecode_problem.nil?
      check_package_id(package_id, "package_id")
      Dep_gecode.GetPackageMin(gecode_problem, package_id)
    end
    def dump()
      raise "Gecode internal failure" if gecode_problem.nil?
      Dep_gecode.VersionProblemDump(gecode_problem)
    end
    def dump_package_var(package_id)
      raise "Gecode internal failure" if gecode_problem.nil?
      check_package_id(package_id, "package_id")
      Dep_gecode.VersionProblemPrintPackageVar(gecode_problem, package_id)
    end

    def package_disabled_count
      raise "Gecode internal failure (package disabled count)" if gecode_problem.nil?
      Dep_gecode.GetDisabledVariableCount(gecode_problem)
    end

    def mark_required(package_id)
      raise "Gecode internal failure (mark_required)" if gecode_problem.nil?
      check_package_id(package_id, "package_id")
      Dep_gecode.MarkPackageRequired(gecode_problem, package_id);
    end

    def mark_preferred_to_be_at_latest(package_id, weight)
      raise "Gecode internal failure (mark_preferred_to_be_at_latest)" if gecode_problem.nil?
      check_package_id(package_id, "package_id")
      Dep_gecode.MarkPackagePreferredToBeAtLatest(gecode_problem, package_id, weight);
    end

    def solve()
      raise "Gecode internal failure (solve)" if gecode_problem.nil?
      solution = GecodeWrapper.new(Dep_gecode.Solve(gecode_problem), debug_logs_on)
      raise "Gecode internal failure (no solution found)" if (solution.nil?)

      raise Exceptions::NoSolutionFound.new(solution) if solution.package_disabled_count > 0
      solution
    end

  end
end
