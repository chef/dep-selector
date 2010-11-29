require 'gecoder'

module DepSelector
  class Dependency
    attr_reader :package, :constraint

    def initialize(package, constraint)
      @package = package
      @constraint = constraint
    end

    def to_s(incl_densely_packed_versions = false)
      range = package.densely_packed_versions[constraint]
      "(#{package.name} #{constraint.to_s}#{incl_densely_packed_versions ? " (#{range})" : ''})"
    end

    def generate_gecode_constraint
      package.gecode_model_var.must_be.in(package.densely_packed_versions[constraint])
    end
  end
end
