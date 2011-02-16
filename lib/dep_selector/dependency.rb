require 'dep_selector/version_constraint'

module DepSelector
  class Dependency
    attr_reader :package, :constraint

    def initialize(package, constraint=nil)
      @package = package
      @constraint = constraint || VersionConstraint.new
    end

    def to_s(incl_densely_packed_versions = false)
      range = package.densely_packed_versions[constraint]
      "(#{package.name} #{constraint.to_s}#{incl_densely_packed_versions ? " (#{range})" : ''})"
    end

    def ==(o)
      o.respond_to?(:package) && package == o.package &&
        o.respond_to?(:constraint) && constraint == o.constraint
    end

    def eql?(o)
      self.class == o.class && self == o
    end

  end
end
