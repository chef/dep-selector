require 'dep_selector/package'

require 'gecoder'

# DependencyGraphs contain Packages, which in turn contain
# PackageVersions. Packages are created at access-time through
# #package
module DepSelector
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

    def to_s
      packages.keys.sort.map{|name| packages[name].to_s}.join("\n")
    end

    # TODO [cw,2010/11/23]: this is a simple but inefficient impl. Do
    # it for realz.
    def clone
      Marshal.load(Marshal.dump(self))
    end
  end
end
