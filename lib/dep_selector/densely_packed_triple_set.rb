require 'chef/version_class'

module DepSelector
  class DenselyPackedTripleSet
    attr_reader :sorted_triples

    def initialize(triples)
      # TODO [cw/mark,2010/11/22]: JANKY!
      # Accept strings in form x, x.y, or x.y.z or things that map to such strings...
      @sorted_triples = triples.map{|triple| Chef::Version.new(triple) }.sort.map{|t| t.to_s}
      @triple_to_index = {}
      @sorted_triples.each_with_index{|triple, idx| @triple_to_index[triple.to_s] = idx}
    end

    def range
      Range.new(0, @sorted_triples.size-1)
    end

    def index(triple)
      @triple_to_index[triple]
    end

    def [](constraint)
      # TODO [cw/mark,2010/11/22]: don't actually need an array here, re-write
      range = []
      started = false
      done = false
      sorted_triples.each_with_index do |triple, idx|
        raise "Currently only handle continuous" if (range.any? && range.last+1 != idx)
        range << idx if constraint.include?(triple)
      end
      Range.new(range.first, range.last)
    end
  end
end
