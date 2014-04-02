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

require 'dep_selector/package_version'
require 'dep_selector/densely_packed_set'

module DepSelector
  class Package
    attr_reader :dependency_graph, :name, :versions

    def initialize(dependency_graph, name)
      @dependency_graph = dependency_graph
      @name = name
      @versions = []
    end

    def add_version(version)
      versions << (pv = PackageVersion.new(self, version))
      pv
    end

    # Note: only invoke this method after all PackageVersions have been added
    def densely_packed_versions
      @densely_packed_versions ||= DenselyPackedSet.new(versions.map{|pkg_version| pkg_version.version})
    end

    # Given a version, this method returns the corresonding
    # PackageVersion. Given a version constraint, this method returns
    # an array of matching PackageVersions.
    #--
    # TODO [cw,2011/2/4]: rationalize this with DenselyPackedSet#[]
    def [](version_or_constraint)
      # version constraints must abide the include? contract
      if version_or_constraint.respond_to?(:include?)
        versions.select do |ver|
          version_or_constraint.include?(ver.version)
        end
      else
        versions.find{|pkg_version| pkg_version.version == version_or_constraint}
      end
    end

    # A Package is considered valid if it has at least one version
    def valid?
      versions.any?
    end

    def to_s(incl_densely_packed_versions = false)
      components = []
      components << "Package #{name}"
      if incl_densely_packed_versions
        components << " (#{densely_packed_versions.range})"
      end
      versions.each{|version| components << "\n  #{version.to_s(incl_densely_packed_versions)}"}
      components.flatten.join
    end

    # Note: only invoke this method after all PackageVersions have been added
    def gecode_package_id
      # Note: gecode does naive bounds propagation at every post,
      # which means that any package with exactly one version is
      # considered bound and its dependencies propagated even though
      # there might not be a solution constraint that requires that
      # package to be bound, which means that otherwise-irrelevant
      # constraints (e.g. A1->B1 when the solution constraint is B=2
      # and there is nothing to induce a dependency on A) can cause
      # unsatisfiability. Therefore, we want every package to have at
      # least two versions, one of which is neither the target of
      # other packages' dependencies nor induces other
      # dependencies. Package version id -1 serves this purpose.
      #
      # TODO [cw, 2011/2/22]: Do we likewise want to leave packages
      # with no versions (the target of an invalid dependency) with
      # two versions in order to allow the solver to explore the
      # invalid portion of the state space instead of naively limiting
      # it for the purposes of having failure count heuristics?
      max = densely_packed_versions.range.max || -1
      @gecode_package_id ||= dependency_graph.gecode_wrapper.add_package(-1, max, 0)
    end

    def generate_gecode_wrapper_constraints
      # if this is a valid package (has versions), we don't need to
      # explicitly call gecode_package_id, because they will do it for
      # us; however, if this package isn't valid (it only exists as an
      # invalid dependency and thus has no versions), the solver gets
      # confused, because we won't have generated its package id by
      # the time it starts solving.
      gecode_package_id
      versions.each{|version| version.generate_gecode_wrapper_constraints }
    end

    def eql?(o)
      # TODO [cw,2011/2/7]: this is really shallow. should implement
      # == for DependencyGraph
      self.class == o.class && name == o.name
    end
    alias :== :eql?

  end
end
