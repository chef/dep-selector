require 'dep_selector/exceptions'

module DepSelector
  class DenselyPackedSet
    attr_reader :sorted_triples

    def initialize(triples)
      @sorted_triples = triples.sort
      @triple_to_index = {}
      @sorted_triples.each_with_index{|triple, idx| @triple_to_index[triple] = idx}
    end

    def range
      Range.new(0, @sorted_triples.size-1)
    end

    def index(triple)
      unless @triple_to_index.has_key?(triple)
        msg = "#{triple} is not a valid version for this package"
        raise Exceptions::InvalidVersion.new(msg)
      end
      @triple_to_index[triple]
    end

    def [](constraint)
      # TODO [cw/mark,2010/11/22]: don't actually need an array here, re-write
      range = []
      started = false
      done = false
      sorted_triples.each_with_index do |triple, idx|
        if constraint.include?(triple)
          raise "Currently only handle continuous gap between #{range.last} and #{idx} \n\tfor #{constraint.to_s} over #{@sorted_triples.join(', ')}" if (range.any? && range.last+1 != idx)
          range << idx
        end
      end

      range.empty? ? Range.new(1,0) : Range.new(range.first, range.last)
    end
  end
end
