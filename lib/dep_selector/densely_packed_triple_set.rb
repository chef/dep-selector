require 'chef/version_class'

module DepSelector
  class DenselyPackedTripleSet
    attr_reader :sorted_triples

    def initialize(triples)
      @sorted_triples = triples.map{|triple| Chef::Version.new(triple) }.sort
      @triple_to_index = {}
      @sorted_triples.each_with_index{|triple, idx| @triple_to_index[triple.to_s] = idx}
    end

    def range
      Range.new(0, @sorted_triples.size-1)
    end

    # TODO: make this method respect more than just the = operator
    def [](constraint)
      if constraint.nil?
        range
      else
        raise "Can't match constraint: #{constraint}" unless constraint =~ /= ([\d.]+)/
          Range.new(@triple_to_index[$1], @triple_to_index[$1])
      end
    end
  end
end
