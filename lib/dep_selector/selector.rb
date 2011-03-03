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
    attr_accessor :dep_graph, :error_reporter

    DEFAULT_ERROR_REPORTER = ErrorReporter::SimpleTreeTraverser.new

    def initialize(dep_graph, error_reporter = DEFAULT_ERROR_REPORTER)
      @dep_graph = dep_graph
      @error_reporter = error_reporter
    end

    # Based on solution_constraints, this method tries to find an
    # assignment of PackageVersions that is compatible with the
    # DependencyGraph. If one cannot be found, the constraints are
    # added one at a time until the first unsatisfiable constraint is
    # detected.
    def find_solution(solution_constraints)
      begin
        # first, try to solve the whole set of constraints
        solve(dep_graph.clone, solution_constraints)
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
        solution_constraints.each_index do |idx|
          workspace = dep_graph.clone
          begin
            solve(workspace, solution_constraints[0..idx])
          rescue Exceptions::NoSolutionFound => nsf
            # pick the first package whose constraints had to be
            # disabled in order to find a solution and generate
            # feedback for it
            most_constrained_package =
              workspace.packages.find do |name, pkg|
                nsf.unsatisfiable_problem.is_package_disabled?(pkg.gecode_package_id)
            end.last
            feedback = error_reporter.give_feedback(dep_graph, solution_constraints, idx, most_constrained_package)
            raise Exceptions::NoSolutionExists.new(feedback, solution_constraints[idx])
          end
        end
      end
    end

    private

    # Given a workspace (a clone of the dependency graph) and an array
    # of SolutionConstraints, this method attempts to find a
    # satisfiable set of <Package, Version> pairs
    def solve(workspace, solution_constraints)
      # generate constraints imposed by the dependency graph
      workspace.generate_gecode_wrapper_constraints
      workspace.each_package{|pkg| puts "package #{pkg.name}, id #{pkg.gecode_package_id}"}

      # create shadow package whose dependencies are the solution constraints
      soln_constraints_pkg_id = workspace.gecode_wrapper.add_package(0, 0, 0)
      
      # generate constraints imposed by solution_constraints
      solution_constraints.each do |soln_constraint|
        # look up the package in the cloned dep_graph that corresponds to soln_constraint
        pkg_name = soln_constraint.package.name
        pkg = workspace.package(pkg_name)
        constraint = soln_constraint.constraint
        unless pkg.valid?
          raise Exceptions::InvalidSolutionConstraint.new("Solution constraint (#{pkg_name} #{constraint.to_s}) specifies a package that does not exist in the dependency graph")
        end
        if pkg[constraint].empty?
          raise Exceptions::InvalidSolutionConstraint.new("Solution constraint (#{pkg_name} #{constraint.to_s}) does not match any versions")
        end

        pkg_id = pkg.gecode_package_id
        # package 0 is created in
        # workspace.generate_gecode_wrapper_constraints and represents
        # a "ghost" package that is automatically bound to version 0
        # and whose dependencies are the solution constraints.
        if constraint
          acceptable_versions = pkg.densely_packed_versions[constraint]
          workspace.gecode_wrapper.add_version_constraint(soln_constraints_pkg_id, 0, pkg_id, acceptable_versions.min, acceptable_versions.max)
        else
          # this restricts the domain of the variable to >= 0, which
          # means -1, the shadow package, cannot be assigned, meaning
          # the package must be bound to an actual version
          workspace.gecode_wrapper.add_version_constraint(soln_constraints_pkg_id, 0, pkg_id, 0, pkg.densely_packed_versions.range.max)
        end
      end

      soln = workspace.gecode_wrapper.solve
      trim_solution(solution_constraints, soln, workspace)
    end

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

  end
end
