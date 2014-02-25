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

require 'rubygems'
$:.unshift(File.expand_path("../../ext/dep_gecode", __FILE__))
require 'dep_selector'
require 'pp'
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.filter_run :focus => true
  config.filter_run_excluding :external => true

  # Tests that randomly fail, but may have value.
  config.filter_run_excluding :volatile => true
end


def setup_constraint(dep_graph, cset)
  cset.each do |cb_version|
    package_name = cb_version["key"].first
    version = DepSelector::Version.new(cb_version["key"].last)
    dependencies = cb_version['value']

    pv = dep_graph.package(package_name).add_version(version)
    dependencies.each_pair do |dep_name, constraint_str|
      constraint = DepSelector::VersionConstraint.new(constraint_str)
      pv.dependencies << DepSelector::Dependency.new(dep_graph.package(dep_name), constraint)
    end
  end
end

def setup_soln_constraints(dep_graph, soln_constraints)
  soln_constraints.map do |elt|
    pkg = dep_graph.package(elt.shift)
    constraint = DepSelector::VersionConstraint.new(elt.shift)
    DepSelector::SolutionConstraint.new(pkg, constraint)
  end
end

def verify_solution(observed, expected)
  versions = expected.inject({}){|acc, elt| acc[elt.first]=DepSelector::Version.new(elt.last) ; acc}
  observed.should == versions
end
