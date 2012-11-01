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
  module Exceptions

    # This exception is what the client of dep_selector should
    # catch. It contains the solution constraint that introduces
    # unsatisfiability, as well as the set of packages that are
    # required to be disabled due to 
    class NoSolutionExists < StandardError
      attr_reader :message, :unsatisfiable_solution_constraint,
                  :disabled_non_existent_packages,
                  :disabled_most_constrained_packages
      def initialize(message, unsatisfiable_solution_constraint,
                     disabled_non_existent_packages = [],
                     disabled_most_constrained_packages = [])
        @message = message
        @unsatisfiable_solution_constraint = unsatisfiable_solution_constraint
        @disabled_non_existent_packages = disabled_non_existent_packages
        @disabled_most_constrained_packages = disabled_most_constrained_packages
      end
    end

    class TimeBoundExceeded < StandardError
    end
    class TimeBoundExceededNoSolution < StandardError
    end

    # This exception is thrown by gecode_wrapper and only used
    # internally
    class NoSolutionFound < StandardError
      attr_reader :unsatisfiable_problem
      def initialize(unsatisfiable_problem=nil)
        @unsatisfiable_problem = unsatisfiable_problem
      end
    end

    # This exception is thrown during Selector#find_solution if any of
    # the solution constraints make finding solution impossible. The
    # two cases are if a solution constraint references a package that
    # doesn't exist or if the constraint on an extant package matches
    # no versions.
    class InvalidSolutionConstraints < ArgumentError
      attr_reader :non_existent_packages, :constrained_to_no_versions
      def initialize(non_existent_packages, constrained_to_no_versions)
        @non_existent_packages = non_existent_packages
        @constrained_to_no_versions = constrained_to_no_versions
      end
    end

    class InvalidVersion < ArgumentError ; end
    class InvalidVersionConstraint < ArgumentError; end

  end
end
