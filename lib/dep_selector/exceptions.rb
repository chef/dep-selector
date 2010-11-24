module DepSelector
  module Exceptions

    # TODO [cw,2010/11/23]: add some way to indicate most constrained
    # variables
    class NoSolutionExists < StandardError
      attr_reader :unsatisfiable_constraint
      def initialize(unsatisfiable_constraint=nil)
        @unsatisfiable_constraint = unsatisfiable_constraint
      end
    end

    class TripleNotDenselyPacked < StandardError
      attr_reader :invalid_triple
      def initialize(invalid_triple)
        @invalid_triple = invalid_triple
      end
    end

  end
end
