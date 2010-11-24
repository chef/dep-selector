module DepSelector
  module Exceptions

    class TripleNotDenselyPacked < StandardError
      attr_reader :invalid_triple
      def initialize(invalid_triple)
        @invalid_triple = invalid_triple
      end
    end

  end
end
