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

describe DepSelector::DenselyPackedSet do

  describe "[]" do
    it "can create a simple set of versions and pick a version by equality" do
      dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
      constraint = DepSelector::VersionConstraint.new("= 2.0.0")
      range = dpt_set[constraint]
      range.first.should == 1
      range.last.should == 1
    end

    it "can create a simple set of versions and pick a version by greater than equal" do
      dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
      constraint = DepSelector::VersionConstraint.new(">= 2.0.0")
      range = dpt_set[constraint]
      range.first.should == 1
      range.last.should == 3
    end

    it "can create a simple set of versions and pick a version by greater than" do
      dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
      constraint = DepSelector::VersionConstraint.new("> 2.0.0")
      range = dpt_set[constraint]
      range.first.should == 2
      range.last.should == 3
    end
  
    it "can create a simple set of versions and pick a version by less than equal" do
      dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
      constraint = DepSelector::VersionConstraint.new("<= 3.0.0")
      range = dpt_set[constraint]
      range.first.should == 0
      range.last.should == 2
    end

    it "can create a simple set of versions and pick a version by less than equal" do
      dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
      constraint = DepSelector::VersionConstraint.new("<= 3.0.0")
      range = dpt_set[constraint]
      range.first.should == 0
      range.last.should == 2
    end

    it "can create a more complex set of versions and pick a version by >~ x.y" do
      dpt_set = DepSelector::DenselyPackedSet.new ["0.1.0", "1.0.0", "1.1", "1.1.1", "1.2", "1.2.1", "1.2.2",
                                                   "2.0.0", "3.0.0", "4.0.0"]
      constraint = DepSelector::VersionConstraint.new("~> 1.1")
      range = dpt_set[constraint]
      range.first.should == 2
      range.last.should == 6
    end

    it "can create a more complex set of versions and pick a version by ~> x.y.z" do
      dpt_set = DepSelector::DenselyPackedSet.new ["0.1.0", "1.0.0", "1.1", "1.1.1", "1.2", "1.2.1", "1.2.2",
                                                   "2.0.0", "3.0.0", "4.0.0"]
      constraint = DepSelector::VersionConstraint.new("~> 1.1.0")
      range = dpt_set[constraint]
      range.first.should == 2
      range.last.should == 3
    end

    it "returns an empty range if the densely packed version is requested for a constraint that matches none of the versions" do
      dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0", "0.0.1"]
      constraint = DepSelector::VersionConstraint.new("> 1.0.0")
      dpt_set[constraint].to_a.should be_empty
    end

  end

  describe "index" do

    it "should return the correct index given a version" do
      versions = ["1.0.0", "2.0.0", "3.0.0"].map{|ver_str| DepSelector::Version.new(ver_str)}
      dpt_set = DepSelector::DenselyPackedSet.new(versions)

      dpt_set.index(DepSelector::Version.new("1.0")).should == 0
      dpt_set.index(DepSelector::Version.new("1.0.0")).should == 0

      dpt_set.index(DepSelector::Version.new("2.0")).should == 1
      dpt_set.index(DepSelector::Version.new("2.0.0")).should == 1

      dpt_set.index(DepSelector::Version.new("3.0")).should == 2
      dpt_set.index(DepSelector::Version.new("3.0.0")).should == 2
    end

    it "errors if the densely packed version is requested for an invalid element" do
      dpt_set = DepSelector::DenselyPackedSet.new ["1.0.0"]
      lambda{ dpt_set.index("2.0.0") }.should raise_error(DepSelector::Exceptions::InvalidVersion)
    end

  end
end
