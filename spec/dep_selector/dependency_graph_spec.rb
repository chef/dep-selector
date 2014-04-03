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

require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

describe DepSelector::DependencyGraph do

  describe "package" do
    it "creates a package based on the name and returns the same object on subsequent accesses" do
      dep_graph = DepSelector::DependencyGraph.new
      pkg = dep_graph.package("A")
      pkg.name.should == "A"
      dep_graph.package("A").should === pkg
    end
  end

  describe "clone" do
    it "performs a deep copy" do
      dg1 = DepSelector::DependencyGraph.new
      dg2 = dg1.clone
      dg2.package("should only exist in dg2")
      dg1.packages.should be_empty

      dg1.package("foo")
      dg2 = dg1.clone
      dg2.packages.should have_key("foo")
      dg2.package("foo").add_version("1.0.0")
      dg1.package("foo").versions.should be_empty
    end

    it "creates correct references in package, version, and dependency objects" do
      dg1 = DepSelector::DependencyGraph.new
      original_pkg_a = dg1.package("A").add_version("1.0.0")
      b_v2 = dg1.package("B").add_version("2.0.0")

      dep = DepSelector::Dependency.new(dg1.package("A"), ">= 0.0.0")

      b_v2.dependencies << dep

      copy = dg1.clone
      copied_package_a = copy.package("A")
      copied_package_b = copy.package("B")

      copied_package_a.should_not equal(original_pkg_a)

      copy.package("A").dependency_graph.should equal(copy)
      copy.package("A").should have(1).versions
      copied_pkg_a_v1_0_0 = copy.package("A").versions.first
      copied_pkg_a_v1_0_0.package.should equal(copied_package_a)

      copied_package_b_v2_0_0 = copied_package_b.versions.first
      copied_package_b_v2_0_0.should have(1).dependencies

      copied_dependency = copied_package_b_v2_0_0.dependencies.first
      copied_dependency.package.should equal(copied_package_a)

      # Object equality isn't strictly necessary for the implementation, but
      # object reuse improves perf.
      copied_dependency.constraint.should equal(dep.constraint)
    end

  end
end
