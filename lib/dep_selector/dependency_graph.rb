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

require 'dep_selector/package'
require 'dep_selector/gecode_wrapper'

# DependencyGraphs contain Packages, which in turn contain
# PackageVersions. Packages are created at access-time through
# #package
module DepSelector
  class DependencyGraph

    DebugOptionFile = "/tmp/DepSelectorDebugOn"

    attr_reader :packages

    def initialize
      @packages = {}
    end

    def package(name)
      packages.has_key?(name) ? packages[name] : (packages[name]=Package.new(self, name))
    end

    def has_package?(name)
      packages.has_key?(name)
    end

    def each_package
      packages.each do |name, pkg|
        yield pkg
      end
    end

    def gecode_wrapper
      raise "Must invoke generate_gecode_wrapper_constraints before attempting to access gecode_wrapper" unless @gecode_wrapper
      @gecode_wrapper
    end

    # Note: only invoke this method once all Packages and
    # PackageVersions have been added.
    def generate_gecode_wrapper_constraints(packages_to_include_in_solve=nil)
      unless @gecode_wrapper
        packages_in_solve =
          if packages_to_include_in_solve
            packages_to_include_in_solve
          else
            packages.map{ |name, pkg| pkg }
          end

        debugFlag = DebugOptionFile && File::exists?(DebugOptionFile)
        # In addition to all the packages that the user specified,
        # there is a "ghost" package that contains the solution
        # constraints. See Selector#solve for more information.
        @gecode_wrapper = GecodeWrapper.new(packages_in_solve.size + 1, debugFlag)
        packages_in_solve.each{ |pkg| pkg.generate_gecode_wrapper_constraints }
      end
    end

    def gecode_model_vars
      packages.inject({}){|acc, elt| acc[elt.first] = elt.last.gecode_model_var ; acc }
    end

    def to_s(incl_densely_packed_versions = false)
      packages.keys.sort.map{|name| packages[name].to_s(incl_densely_packed_versions)}.join("\n")
    end

    # Does a combined clone and filter operation. Creates a deep copy via a
    # similar process as #clone, but filters out packages and versions that do
    # not satisfy the given constraints (or dependencies of those constraints).
    def create_subgraph_for_constraints(constraints)
      subgraph = self.class.new
      add_matching_packages(constraints, subgraph)
      copy
    end

    # Does a mostly deep copy of this graph, creating new Package,
    # PackageVersion, and Dependency objects in the copy graph. Version and
    # VersionConstraint objects are re-used from the existing graph.
    def clone
      copy = self.class.new
      @packages.each do |name, package|
        copy_package = copy.package(name)

        package.versions.each do |package_version|
          copy_pkg_version = copy_package.add_version(package_version.version)
          package_version.dependencies.each do |pkg_vers_dep|
            dep_pkg_name = pkg_vers_dep.package.name
            copy_dependency = DepSelector::Dependency.new(copy.package(dep_pkg_name), pkg_vers_dep.constraint)
            copy_pkg_version.dependencies << copy_dependency
          end
        end
      end
      copy
    end

    ##
    # Methods called by other instances during #create_subgraph_for_constraints
    ##

    protected

    # Given a workspace and solution constraints, this method returns
    # an array that includes only packages that can be induced by the
    # solution constraints.
    def add_matching_packages(soln_constraints, subgraph)
      soln_constraints_on_non_existent_packages = []
      soln_constraints_that_match_no_versions = []

      soln_constraints.each do |soln_constraint|

        # This is the code from Selector#process_soln_constraints that is used
        # to generate the error messages when solution constraints require
        # packages that don't exist at all or package versions that don't exist at all
        # generate constraints imposed by solution_constraints
        #####
        # look up the package in the cloned dep_graph that corresponds to soln_constraint
        pkg_name = soln_constraint.package.name
        pkg = package(pkg_name)
        constraint = soln_constraint.constraint

        # record invalid solution constraints and raise an exception
        # afterwards
        unless pkg.valid? || (valid_packages && valid_packages.include?(pkg))
          soln_constraints_on_non_existent_packages << soln_constraint
          next
        end
        if pkg[constraint].empty?
          soln_constraints_that_match_no_versions << soln_constraint
          next
        end

        # Initiate the recursive call that finds all the deps and adds them to
        # subgraph
        add_dependent_matching_packages(soln_constraint.package, soln_constraints, subgraph)
      end

      if soln_constraints_on_non_existent_packages.any? || soln_constraints_that_match_no_versions.any?
        raise Exceptions::InvalidSolutionConstraints.new(soln_constraints_on_non_existent_packages,
                                                         soln_constraints_that_match_no_versions)
      end

      subgraph
    end

    def add_dependent_matching_packages(curr_pkg, soln_constraints, subgraph)

      # don't follow circular paths or duplicate work
      return if subgraph.has_package?(curr_pkg.name)

      # Deep clone the package on the cloned depgraph
      copy_package = subgraph.package(curr_pkg.name)

      curr_pkg.versions.each do |curr_pkg_ver|
        # skip versions that don't satisfy top-level dep constraints
        next unless should_include_in_subgraph?(curr_pkg, curr_pkg_ver, soln_constraints)
        # clone the version to the subgraph
        copy_pkg_version = copy_package.add_version(curr_pkg_ver.version)

        curr_pkg_ver.dependencies.each do |dep|
          # clone the dependency
          dep_pkg_name = pkg_vers_dep.package.name
          copy_dependency = DepSelector::Dependency.new(copy.package(dep_pkg_name), pkg_vers_dep.constraint)
          copy_pkg_version.dependencies << copy_dependency

          # add dependent packages to the subgraph
          add_dependent_matching_packages(dep.package, soln_constraints, subgraph)
        end
      end

    end

    def should_include_in_subgraph?(package, version, soln_constraints)
      # There are a few strategies we could use to trim package versions:
      # * add all packages and possible dependencies, then remove invalid
      # versions at the end. Downside of this is that we will have already
      # added their dependencies.
      # * while looping over constraints, filter versions based on the current
      # constraint in the loop. Downside of this is that if we're given
      # multiple constraints on the same package, we might keep packages that
      # don't satisfy both constraints. Also, we won't apply constraints to
      # dependencies if a constraint also applies to a transitive dep of
      # another package.
      # * check all constraints for each package version we add to the
      # subgraph. Downside is we're adding an O(N) loop nested in other loops.
      # This is the approach we take here.
      relevant_constraints = soln_constraints.select { |constraint| constraint.name == package.name }
      relevant_constraints.all? { |constraint| constraint.constraint.include?(version) }
    end

  end
end
