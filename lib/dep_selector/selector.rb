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

require 'timeout'
require 'dep_selector/dependency_graph'
require 'dep_selector/exceptions'
require 'dep_selector/error_reporter'
require 'dep_selector/error_reporter/simple_tree_traverser'

# A Selector contains the a DependencyGraph, which is populated with
# the dependency relationships, and an array of solution
# constraints. When a solution is asked for (via #find_solution),
# either a valid assignment is returned or the first solution
# constraint that makes a solution impossible.
module DepSelector
  class Selector
    attr_accessor :dep_graph, :error_reporter, :time_bound

    DEFAULT_ERROR_REPORTER = ErrorReporter::SimpleTreeTraverser.new

    def initialize(dep_graph, time_bound = 5, error_reporter = DEFAULT_ERROR_REPORTER)
      @dep_graph = dep_graph
      @time_bound = time_bound
      @error_reporter = error_reporter
    end

    # Based on solution_constraints, this method tries to find an
    # assignment of PackageVersions that is compatible with the
    # DependencyGraph. If one cannot be found, the constraints are
    # added one at a time until the first unsatisfiable constraint is
    # detected. Once the unsatisfiable solution constraint is
    # identified, required non-existent packages and the most
    # constrained packages are identified and thrown in a
    # NoSolutionExists exception.
    #
    # If a solution constraint refers to a package that doesn't exist
    # or the constraint matches no versions, it is considered
    # invalid. All invalid solution constraints are collected and
    # raised in an InvalidSolutionConstraints exception. If
    # valid_packages is non-nil, it is considered the authoritative
    # list of extant Packages; otherwise, Package#valid? is used. This
    # is useful if the dependency graph represents an already filtered
    # set of packages such that a Package actually exists in your
    # domain but is added to the dependency graph with no versions, in
    # which case Package#valid? would return false even though we
    # don't want to report that the package is non-existent.
    def find_solution(solution_constraints, valid_packages = nil)
      # this is a performance optimization so that packages that are
      # completely unreachable by the solution constraints don't get
      # added to the CSP
      packages_to_include_in_solve = trim_unreachable_packages(dep_graph, solution_constraints)

      begin
        Timeout::timeout(@time_bound, Exceptions::TimeBoundExceeded) do
          # first, try to solve the whole set of constraints
          solve(dep_graph.clone, solution_constraints, valid_packages, packages_to_include_in_solve)
        end
      rescue Exceptions::NoSolutionFound
        # since we're here, solving the whole system failed, so add
        # the solution_constraints one-by-one and try to solve in
        # order to find the constraint that breaks the system in order
        # to give helpful debugging info
        #
        # TODO [cw,2010/11/28]: for an efficiency gain, instead of
        # continually re-building the problem and looking for a
        # solution, turn solution_constraints into a Generator and
        # iteratively add and solve in order to re-use
        # propagations. This will require separating setting up the
        # constraints from searching for the solution.
        Timeout::timeout(@time_bound, Exceptions::TimeBoundExceededNoSolution) do
          solution_constraints.each_index do |idx|
            workspace = dep_graph.clone
            begin
              solve(workspace, solution_constraints[0..idx], valid_packages, packages_to_include_in_solve)
            rescue Exceptions::NoSolutionFound => nsf
              disabled_packages =
                packages_to_include_in_solve.inject([]) do |acc, elt|
                pkg = workspace.package(elt.name)
                acc << pkg if nsf.unsatisfiable_problem.is_package_disabled?(pkg.gecode_package_id)
                acc
              end
              # disambiguate between packages disabled becuase they
              # don't exist and those that have otherwise problematic
              # constraints
              disabled_non_existent_packages = []
              disabled_most_constrained_packages = []
              disabled_packages.each do |disabled_pkg|
                disabled_collection =
                  if disabled_pkg.valid? || (valid_packages && valid_packages.include?(disabled_pkg))
                    disabled_most_constrained_packages
                  else
                    disabled_non_existent_packages
                  end
                disabled_collection << disabled_pkg
              end

              # Pick the first non-existent or most-constrained package
              # that was required or the package whose constraints had
              # to be disabled in order to find a solution and generate
              # feedback for it. We only report feedback for one
              # package, because it is in fact actionable and dispalying
              # feedback for every disabled package would probably be
              # too long. The full set of disabled packages is
              # accessible in the NoSolutionExists exception.
              disabled_package_to_report_on = disabled_non_existent_packages.first ||
                disabled_most_constrained_packages.first
              feedback = error_reporter.give_feedback(dep_graph, solution_constraints, idx,
                                                      disabled_package_to_report_on)

              raise Exceptions::NoSolutionExists.new(feedback, solution_constraints[idx],
                                                     disabled_non_existent_packages,
                                                     disabled_most_constrained_packages)
            end
          end
        end
      end
    end

    private

    # Given a workspace (a clone of the dependency graph) and an array
    # of SolutionConstraints, this method attempts to find a
    # satisfiable set of <Package, Version> pairs.
    def solve(workspace, solution_constraints, valid_packages, packages_to_include_in_solve)
      # map packages in packages_to_include_in_solve into
      # corresponding workspace packages and generate constraints
      # imposed by the dependency graph
      packages_in_solve = packages_to_include_in_solve.map{|pkg| workspace.package(pkg.name)}
      workspace.generate_gecode_wrapper_constraints(packages_in_solve)

      # validate solution_constraints and generate its constraints
      process_soln_constraints(workspace, solution_constraints, valid_packages)

      # solve and trim the solution down to only the
      soln = workspace.gecode_wrapper.solve
      trim_solution(solution_constraints, soln, workspace)
    end

    # This method validates SolutionConstraints and adds their
    # corresponding constraints to the workspace.
    def process_soln_constraints(workspace, solution_constraints, valid_packages)
      gecode = workspace.gecode_wrapper

      # create shadow package whose dependencies are the solution constraints
      soln_constraints_pkg_id = gecode.add_package(0, 0, 0)

      soln_constraints_on_non_existent_packages = []
      soln_constraints_that_match_no_versions = []

      # generate constraints imposed by solution_constraints
      solution_constraints.each do |soln_constraint|
        # look up the package in the cloned dep_graph that corresponds to soln_constraint
        pkg_name = soln_constraint.package.name
        pkg = workspace.package(pkg_name)
        constraint = soln_constraint.constraint

        # record invalid solution constraints and raise an exception
        # afterwards
        unless pkg.valid? || (valid_packages && valid_packages.include?(pkg))
          soln_constraints_on_non_existent_packages << soln_constraint
          next
        end
        if pkg[constraint].empty?
          soln_constraints_that_match_no_versions << soln_constraint
          next
        end

        pkg_id = pkg.gecode_package_id

        gecode.mark_preferred_to_be_at_latest(pkg_id, 10)
        gecode.mark_required(pkg_id)

        if constraint
          acceptable_versions = pkg.densely_packed_versions[constraint]
          gecode.add_version_constraint(soln_constraints_pkg_id, 0, pkg_id, acceptable_versions.min, acceptable_versions.max)
        else
          # this restricts the domain of the variable to >= 0, which
          # means -1, the shadow package, cannot be assigned, meaning
          # the package must be bound to an actual version
          gecode.add_version_constraint(soln_constraints_pkg_id, 0, pkg_id, 0, pkg.densely_packed_versions.range.max)
        end
      end

      if soln_constraints_on_non_existent_packages.any? || soln_constraints_that_match_no_versions.any?
        raise Exceptions::InvalidSolutionConstraints.new(soln_constraints_on_non_existent_packages,
                                                         soln_constraints_that_match_no_versions)
      end
    end

    # Given an assignment of versions to packages, filter down to only
    # the required assignments
    def trim_solution(soln_constraints, soln, workspace)
      trimmed_soln = {}

      soln_constraints.each do |soln_constraint|
        package = workspace.package(soln_constraint.package.name)

        expand_package(trimmed_soln, package, soln)
      end

      trimmed_soln
    end

    def expand_package(trimmed_soln, package, soln)
      # don't expand packages that we've already expanded
      return if trimmed_soln.has_key?(package.name)

      # add the package's assignment to the trimmed solution
      densely_packed_version = soln.get_package_version(package.gecode_package_id)
      version = package.densely_packed_versions.sorted_elements[densely_packed_version]
      trimmed_soln[package.name] = version

      # expand the package's dependencies
      pkg_version = package[version]
      pkg_version.dependencies.each do |pkg_dep|
        expand_package(trimmed_soln, pkg_dep.package, soln)
      end
    end

    # Given a workspace and solution constraints, this method returns
    # an array that includes only packages that can be induced by the
    # solution constraints.
    def trim_unreachable_packages(workspace, soln_constraints)
      reachable_packages = []
      soln_constraints.each do |soln_constraint|
        find_reachable_packages(workspace,
                                soln_constraint.package,
                                soln_constraint.constraint,
                                reachable_packages)
      end

      reachable_packages
    end

    def find_reachable_packages(workspace, curr_pkg, version_constraint, reachable_packages)
      # TODO [cw, 2011/3/11]: if we really want to minimize the number
      # of packages we add to reachable_packages, we should go back to
      # expanding only the versions of curr_pkg that meet
      # version_constraint and modify the early exit in this method to
      # trigger on PackageVersions, not just Package.

      # don't follow circular paths or duplicate work
      return if reachable_packages.include?(curr_pkg)

      # add curr_pkg to reachable_packages and expand its versions'
      # dependencies
      reachable_packages << curr_pkg
      curr_pkg.versions.each do |curr_pkg_ver|
        curr_pkg_ver.dependencies.each do |dep|
          find_reachable_packages(workspace, dep.package, dep.constraint, reachable_packages)
        end
      end

    end

  end
end
