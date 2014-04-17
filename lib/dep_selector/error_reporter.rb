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

module DepSelector
  class ErrorReporter

    attr_reader :workspace
    attr_reader :solution_constraints
    attr_reader :idx
    attr_reader :dep_graph
    attr_reader :valid_packages
    attr_reader :packages_to_include_in_solve
    attr_reader :nsf

    def initialize(workspace, solution_constraints, idx, dep_graph, valid_packages, packages_to_include_in_solve, nsf)
      @workspace                    = workspace
      @solution_constraints         = solution_constraints
      @idx                          = idx
      @dep_graph                    = dep_graph
      @valid_packages               = valid_packages
      @packages_to_include_in_solve = packages_to_include_in_solve
      @nsf                          = nsf
    end

    def handle_errors
      raise "Sub-class must implement new handle_errors API, the dependency injection API has changed"
    end

    private

    def most_constrained_pkg
      # Pick the first non-existent or most-constrained package
      # that was required or the package whose constraints had
      # to be disabled in order to find a solution and generate
      # feedback for it. We only report feedback for one
      # package, because it is in fact actionable and dispalying
      # feedback for every disabled package would probably be
      # too long. The full set of disabled packages is
      # accessible in the NoSolutionExists exception.
      @most_constrained_pkg ||= disabled_non_existent_packages.first ||
        disabled_most_constrained_packages.first
    end

    def disabled_packages
      @disabled_packages ||= packages_to_include_in_solve.inject([]) do |acc, elt|
        pkg = workspace.package(elt.name)
        acc << pkg if nsf.unsatisfiable_problem.is_package_disabled?(pkg.gecode_package_id)
        acc
      end
      @disabled_packages ||= []
    end

    def classify_disabled_packages
      # disambiguate between packages disabled becuase they
      # don't exist and those that have otherwise problematic
      # constraints
      @disabled_non_existent_packages = []
      @disabled_most_constrained_packages = []
      disabled_packages.each do |disabled_pkg|
        if disabled_pkg.valid? || (valid_packages && valid_packages.include?(disabled_pkg))
          disabled_most_constrained_packages << disabled_pkg
        else
          disabled_non_existent_packages << disabled_pkg
        end
      end
    end

    def disabled_non_existent_packages
      classify_disabled_packages if @disabled_non_existent_packages.nil?
      @disabled_non_existent_packages
    end

    def disabled_most_constrained_packages
      classify_disabled_packages if @disabled_most_constrained_packages.nil?
      @disabled_most_constrained_packages
    end

  end
end
