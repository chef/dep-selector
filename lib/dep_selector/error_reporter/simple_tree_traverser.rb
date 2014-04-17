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

require 'dep_selector/error_reporter'

# This error reporter simply maps the versions of packages explicitly
# included in the list of solution constraints to the restrictions
# placed on the most constrained package.
module DepSelector
  class ErrorReporter
    class SimpleTreeTraverser < ErrorReporter

      def give_feedback(dep_graph, soln_constraints, unsatisfiable_constraint_idx, most_constrained_pkg)
        unsatisfiable_soln_constraint = soln_constraints[unsatisfiable_constraint_idx]
        feedback = "Unable to satisfy constraints on package #{most_constrained_pkg.name}"
        feedback << ", which does not exist," unless most_constrained_pkg.valid?
        feedback << " due to solution constraint #{unsatisfiable_soln_constraint}. "

        all_paths = paths_from_soln_constraints_to_pkg_constraints(dep_graph, soln_constraints, most_constrained_pkg)
        collapsed_paths = collapse_adjacent_paths(all_paths).map{|collapsed_path| "[#{print_path(collapsed_path).join(' -> ')}]"}

        feedback << "Solution constraints that may result in a constraint on #{most_constrained_pkg.name}: #{collapsed_paths.join(', ')}"
      end

      private

      def paths_from_soln_constraints_to_pkg_constraints(dep_graph, soln_constraints, most_constrained_pkg)
        all_paths = []
        soln_constraints.each do |soln_constraint|
          paths_to_pkg(dep_graph,
                       soln_constraint.package,
                       soln_constraint.constraint,
                       most_constrained_pkg,
                       [],
                       all_paths)
        end

        all_paths
      end

      def paths_to_pkg(dep_graph, curr_pkg, version_constraint, target_pkg, curr_path, all_paths)
        if curr_pkg == target_pkg
          # register the culminating constraint
          all_paths.push(Array.new(curr_path).push(SolutionConstraint.new(curr_pkg, version_constraint)))
          return
        end

        # curr_pkg has no versions, it is invalid so don't recurse
        if curr_pkg.versions.empty?
          # TODO [cw, 2011/2/17]: find a way to track these invalid
          # packages and return as potential conflict-causing
          # constraints.
          return
        end

        if curr_path.select{|elt| elt.package == curr_pkg}.any?
          # TODO [cw, 2011/2/18]: this indicates a circular dependency
          # in the dependency graph. This might be useful warning
          # information to report to the user.
          return
        end

        # determine all versions of curr_pkg that match
        # version_constraint and recurse into them
        seen_dep_trees = {}
        curr_pkg[version_constraint].each do |curr_pkg_ver|
          dep_key = curr_pkg_ver.dependencies
          next if seen_dep_trees.has_key?(dep_key)
          curr_path.push(curr_pkg_ver)
          curr_pkg_ver.dependencies.each do |dep|
            next if curr_pkg.name == dep.package.name
            paths_to_pkg(dep_graph, dep.package, dep.constraint, target_pkg, curr_path, all_paths)
          end
          seen_dep_trees[dep_key] = true
          curr_path.pop
        end
      end

      # This is a simple collapsing function. For each adjacent path,
      # if there is only one element different between the two paths
      # and their packages are the same (meaning only the version
      # binding is different), then the elements are considered
      # collasable. The merged path has all the common elements and a
      # set containing the two version bindings in place of the
      # contentious path item.
      def collapse_adjacent_paths(paths)
        return paths if paths.length < 2

        paths.inject([]) do |collapsed_paths, path|
          merge_path_into_collapsed_paths(collapsed_paths, path)
        end
      end

      def print_path(path)
        path.map do |step|
          if step.respond_to? :version
            "(#{step.package.name} = #{step.version})"
          elsif step.respond_to? :constraint
            step.to_s
          elsif step.kind_of?(Array)
            # TODO [cw, 2011/2/23]: consider detecting complete
            # ranges here instead of calling each out individually
            "(#{step.first.package.name} = {#{step.map{|elt| "#{elt.version}"}.join(',')}})"
          else
            raise "don't know how to print step"
          end
        end
      end

      # collapses path_under_consideration onto the end of
      # collapsed_paths or adds a new path to be used in the next
      # round(s) of collapsing.
      #
      # Note: collapsed_paths is side-effected
      def merge_path_into_collapsed_paths(collapsed_paths, path_under_consideration)
        curr_collapsed_path = collapsed_paths.last

        # if there is no curr_collapsed_path or it isn't the same
        # length as path_under_consideration, then they cannot
        # possibly be mergeable
        if curr_collapsed_path.nil? || curr_collapsed_path.length != path_under_consideration.length
          # TODO [cw.2011/2/7]: do we need this to be a new array, or
          # can we save ourselves a little memory and work by just
          # pushing the reference to path_under_consideration?
          return collapsed_paths << Array.new(path_under_consideration)
        end

        # lengths are equal, so find the first path element where
        # curr_collapsed_path and path_under_consideration diverge, if
        # that is the only unequal element, it's for the same package,
        # and they are both PackageVersion objects then merge;
        # otherwise, this is a new path
        #
        # TODO [cw,2011/2/7]: should we merge even if they're not for
        # the same package?
        unequal_idx = nil
        merged_set = nil
        mergeable = true
        path_under_consideration.each_with_index do |path_element, curr_idx|
          if path_element != curr_collapsed_path[curr_idx]
            unless unequal_idx
              merged_set = [curr_collapsed_path[curr_idx]].flatten
              if merged_set.first.package == path_element.package &&
                  merged_set.first.is_a?(PackageVersion) &&
                  path_element.is_a?(PackageVersion)
                merged_set << path_element
              else
                mergeable = false
                break
              end
              unequal_idx = curr_idx
            else
              # this is the second place they are unequal. fast-fail,
              # because we know we can't merge the paths.
              mergeable = false
              break
            end
          end
        end

        if unequal_idx && mergeable
          curr_collapsed_path[unequal_idx] = merged_set
        else
          collapsed_paths << Array.new(path_under_consideration)
        end

        collapsed_paths
      end

    end
  end
end
