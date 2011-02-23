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
    #
    # If a block is passed, it is used as the objective function. It
    # must take an argument that represents a solution and must
    # produce an object comparable with Float, where greater than
    # represents a better solution for the domain.
    def find_solution(solution_constraints, bottom = ObjectiveFunction::MinusInfinity,  &block)
      begin
        # first, try to solve the whole set of constraints
        solve(solution_constraints, bottom, &block)
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
          begin
            solve(solution_constraints[0..idx], bottom, &block)
          rescue Exceptions::NoSolutionFound
            most_constrained_package = dep_graph.package('X') # TODO: FOR TESTING ONLY!
            feedback = error_reporter.give_feedback(dep_graph, solution_constraints, idx, most_constrained_package)
            raise Exceptions::NoSolutionExists.new(feedback, solution_constraints[idx])
          end
        end
      end
    end

    private

    # Clones the dependency graph, applies the solution_constraints,
    # and attempts to find a solution.
    def solve(solution_constraints, bottom = ObjectiveFunction::MinusInfinity, &block)
      workspace = dep_graph.clone

      # generate constraints imposed by the dependency graph
      workspace.generate_gecode_wrapper_constraints

      # create shadow package whose dependencies are the solution constraints
      soln_constraints_pkg_id = workspace.gecode_wrapper.add_package(0, 0, 0)

      # generate constraints imposed by solution_constraints
      solution_constraints.each do |soln_constraint|
        # look up the package in the cloned dep_graph that corresponds to soln_constraint
        pkg_name = soln_constraint.package.name
        pkg = workspace.package(pkg_name)
        unless pkg.valid?
          raise Exceptions::InvalidPackage.new("#{pkg_name} does not exist in the dependency graph or has no versions")
        end
        constraint = soln_constraint.constraint

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

      # if a block was specified, use that as the objective function;
      # otherwise, just find any solution
      if block_given?
        raise NotImplemented, "Objective function functionality has been temporarily removed while we move to the GecodeWrapper interface to gecode"
        objective_function = ObjectiveFunction.new(bottom, &block)
        workspace.each_solution do |soln|
          trimmed_soln = trim_solution(solution_constraints, soln)
          objective_function.consider(trimmed_soln)
        end
        objective_function.best_solution
      else
        soln = workspace.gecode_wrapper.solve
        trim_solution(solution_constraints, soln, workspace)
      end
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
