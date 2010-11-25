module DepSelector
  class ObjectiveFunction
    attr_reader :best_solution, :best_solution_value
    
    # -1.0/0 negative infinity
    MinusInfinity = -1.0/0

    def initialize(bottom = MinusInfinity, &evaluation_block)
      pp :ObjectiveFunctionInit=>bottom
      @evaluate_solution = evaluation_block
      @best_solution_value = bottom
    end

    def consider(soln)
      puts "considering solution:"

      if (new_soln_value = @evaluate_solution.call(soln)) > best_solution_value
        puts "better soln found: #{new_soln_value} > #{best_solution_value}"
        # TODO [cw,2010/11/21]: this is a janky way to extract the
        # bindings of a solution, because Gecode::Mixin doesn't seem
        # to have a way to store a particular solution in the middle
        # of solving. Is there a better way to do this?
        @best_solution = soln
        @best_solution_value = new_soln_value
      end

      puts "\n\n"
    end
  end
end
