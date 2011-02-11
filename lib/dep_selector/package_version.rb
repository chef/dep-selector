module DepSelector
  class PackageVersion
    attr_accessor :package, :version, :dependencies

    def initialize(package, version)
      @package = package
      @version = version
      @dependencies = []
    end

    def generate_gecode_constraints
      pkg_mv = package.gecode_model_var
      pkg_densely_packed_version = package.densely_packed_versions.index(version)

      guard = (pkg_mv.must == pkg_densely_packed_version)
      conjunction = dependencies.inject(guard){ |acc, dep| acc & dep.generate_gecode_constraint }
      conjunction | (pkg_mv.must_not == pkg_densely_packed_version)
    end

    def to_s(incl_densely_packed_versions = false)
      components = []
      components << "#{version}"
      if incl_densely_packed_versions
        components << " (#{package.densely_packed_versions.index(version)})"
      end
      components << " -> [#{dependencies.map{|d|d.to_s(incl_densely_packed_versions)}.join(', ')}]"
      components.join
    end

    def hash
      # Didn't put any thought or research into this, probably can be
      # done better
      to_s.hash
    end

    def eql?(o)
      o.class == self.class &&
        package == o.package &&
        version == o.version &&
        dependencies == o.dependencies
    end
    alias :== :eql?

    def to_hash
      { :package_name => package.name, :version => version }
    end

  end
end
