#
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'dep_selector/solution_constraint'

# This also tests Dependency
describe DepSelector::SolutionConstraint do

  describe "equality testing" do

    before do
      @sc1_1 = DepSelector::SolutionConstraint.new(DepSelector::Package.new(nil, 'A'), DepSelector::Version.new("1.0.0"))
      @sc1_2 = DepSelector::SolutionConstraint.new(DepSelector::Package.new(nil, 'A'), DepSelector::Version.new("1.0.0"))
      @dep1_1 = DepSelector::Dependency.new(DepSelector::Package.new(nil, 'A'), DepSelector::Version.new("1.0.0"))
      @dep1_2 = DepSelector::Dependency.new(DepSelector::Package.new(nil, 'A'), DepSelector::Version.new("1.0.0"))
    end

    describe "==" do
      it "should be true when the objects are equal" do
        @sc1_1.should == @sc1_2
        @sc1_1.should == @dep1_1
        @dep1_1.should == @sc1_1
        @dep1_1.should == @dep1_2
      end
    end

    describe "eql?" do
      it "should be true when an object of the same type is ==" do
        @sc1_1.should eql(@sc1_2)
        @dep1_1.should eql(@dep1_2)
      end

      it "should be false when comparing to an object of a different type" do
        @sc1_1.should_not eql(@dep1)
        @dep1.should_not eql(@sc1_1)
      end
    end

  end

end
