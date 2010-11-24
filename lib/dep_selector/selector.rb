require 'dep_selector/dependency_graph'
require 'dep_selector/exceptions'

# A Selector contains the a DependencyGraph, which is populated with
# the dependency relationships, and an array of solution
# constraints. When a solution is asked for (via #find_solution),
# either a valid assignment is returned or the first solution
# constraint that makes a solution impossible.
module DepSelector
  class Selector
    attr_accessor :dep_graph

    def initialize(dep_graph)
      @dep_graph = dep_graph
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
    def find_solution(solution_constraints, &block)
      begin
        # first, try to solve the whole set of constraints
        solve(solution_constraints, &block)
      rescue Gecode::NoSolutionError
        # since we're here, solving the whole system failed, so add
        # the solution_constraints one-by-one and try to solve in
        # order to find the constraint that breaks the system in order
        # to give helpful debugging info
        solution_constraints.each_index do |idx|
          begin
            solve(solution_constraints[0..idx], &block)
          rescue Gecode::NoSolutionError
            raise Exceptions::NoSolutionExists.new(solution_constraints[idx])
          end
        end
      end
    end

    private

    # Clones the dependency graph, applies the solution_constraints,
    # and attempts to find a solution.
    def solve(solution_constraints, &block)
      workspace = dep_graph.clone

      # generate constraints imposed by the dependency graph
      workspace.generate_gecode_constraints

      # generate constraints imposed by solution_constraints
      solution_constraints.each do |package_constraint|
        pkg_name = package_constraint[:name]
        constraint = package_constraint[:version_constraint]
        pkg = workspace.package(pkg_name)

        pkg_mv = pkg.gecode_model_var
        if constraint
          pkg_mv.must_be.in(pkg.densely_packed_versions[constraint])
        end
        workspace.branch_on(pkg_mv)
      end

      # if a block was specified, use that as the objective function;
      # otherwise, just find any solution
      if block_given?
        objective_function = ObjectiveFunction.new(&block)
        workspace.each_solution do |soln|
          objective_function.consider(soln)
        end
        objective_function.best_solution.keys.sort.map do |pkg_name|
          densely_packed_version = objective_function.best_solution[pkg_name]
          dep_graph.package(pkg_name).version_from_densely_packed_version(densely_packed_version)
        end
      else
        workspace.solve!
        workspace.packages.keys.sort.map do |pkg_name|
          densely_packed_version = workspace.package(pkg_name).gecode_model_var.value
          unless densely_packed_version
            dep_graph.package(pkg_name).version_from_densely_packed_version(densely_packed_version)
          else
            nil
          end
        end
      end
    end

  end
end
