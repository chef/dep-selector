require 'dep_selector/package'
require 'dep_selector/gecode_wrapper'

# DependencyGraphs contain Packages, which in turn contain
# PackageVersions. Packages are created at access-time through
# #package
module DepSelector
  class DependencyGraph

    attr_reader :packages, :gecode_wrapper

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

    def generate_gecode_wrapper_constraints
      @gecode_wrapper = GecodeWrapper.new(packages.size + 1)
      each_package{ |pkg| pkg.generate_gecode_wrapper_constraints }
    end

    def gecode_model_vars
      packages.inject({}){|acc, elt| acc[elt.first] = elt.last.gecode_model_var ; acc }
    end

    def to_s(incl_densely_packed_versions = false)
      packages.keys.sort.map{|name| packages[name].to_s(incl_densely_packed_versions)}.join("\n")
    end

    # TODO [cw,2010/11/23]: this is a simple but inefficient impl. Do
    # it for realz.
    def clone
      Marshal.load(Marshal.dump(self))
    end
  end
end
