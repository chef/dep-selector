#
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Mark Anderson (<mark@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module DepSelector
  class PackageVersion
    attr_accessor :package, :version, :dependencies

    def initialize(package, version)
      @package = package
      @version = version
      @dependencies = []
    end

    def generate_gecode_wrapper_constraints
      pkg_densely_packed_version = package.densely_packed_versions.index(version)

      dependencies.each do |dep|
        dep_pkg_range = dep.package.densely_packed_versions[dep.constraint]
        package.dependency_graph.gecode_wrapper.add_version_constraint(package.gecode_package_id, pkg_densely_packed_version, dep.package.gecode_package_id, dep_pkg_range.min, dep_pkg_range.max)
      end
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
