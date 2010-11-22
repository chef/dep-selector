require 'dep_selector/package'

module DepSelector
  # DependencyGraphs contain Packages, which in turn contain
  # PackageVersions
  class DependencyGraph
    include Gecode::Mixin

    attr_reader :packages

    def initialize
      @packages = {}
    end

    def package(name)
      packages.has_key?(name) ? packages[name] : (packages[name]=Package.new(self, name))
    end

    def each_package
      packages.each do |name, pkg|
        yield pkg
      end
    end

    def generate_gecode_constraints
      each_package{ |pkg| pkg.generate_gecode_constraints }
    end

    def gecode_model_vars
      packages.inject({}){|acc, elt| acc[elt.first] = elt.last.gecode_model_var ; acc }
    end

    # TODO [cw,2010/11/21]: See TODO in ObjectiveFunction
    def gecode_model_var_values
      packages.inject({}){|acc, elt| acc[elt.first] = (elt.last.gecode_model_var.value rescue nil) ; acc }
    end
  end
end
