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
  end
end
