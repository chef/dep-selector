module DepSelector
  module Exceptions

    # This exception is what the client of dep_selector should
    # catch. It contains the solution constraint that introduces
    # unsatisfiability, as well as the set of packages that are
    # required to be disabled due to 
    class NoSolutionExists < StandardError
      attr_reader :message, :unsatisfiable_solution_constraint,
                  :disabled_non_existent_packages,
                  :disabled_most_constrained_packages
      def initialize(message, unsatisfiable_solution_constraint,
                     disabled_non_existent_packages,
                     disabled_most_constrained_packages)
        @message = message
        @unsatisfiable_solution_constraint = unsatisfiable_solution_constraint
        @disabled_non_existent_packages = disabled_non_existent_packages
        @disabled_most_constrained_packages = disabled_most_constrained_packages
      end
    end

    class InvalidSolutionConstraint < ArgumentError ; end

    # This exception is thrown by gecode_wrapper and only used
    # internally
    class NoSolutionFound < StandardError
      attr_reader :unsatisfiable_problem
      def initialize(unsatisfiable_problem=nil)
        @unsatisfiable_problem = unsatisfiable_problem
      end
    end

    class InvalidVersion < ArgumentError ; end
    class InvalidVersionConstraint < ArgumentError; end

  end
end
