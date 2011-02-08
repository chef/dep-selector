module DepSelector
  class ErrorReporter

    def give_feedback(workspace, solution_constraints, unsatisfiable_constraint_idx, most_constrained_package)
      raise "Sub-class must implement"
    end

  end
end
