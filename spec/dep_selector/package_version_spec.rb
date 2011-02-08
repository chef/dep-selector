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
require 'dep_selector/package_version'

describe DepSelector::PackageVersion do

  describe "equality testing" do

    before do
      @pv1_1 = DepSelector::PackageVersion.new(DepSelector::Package.new(nil, 'A'), DepSelector::Version.new("1.0.0"))
      @pv1_2 = DepSelector::PackageVersion.new(DepSelector::Package.new(nil, 'A'), DepSelector::Version.new("1.0.0"))
    end

    it "should be true when the objects are equal" do
      @pv1_1.should == @pv1_2
    end

    it "should implement the ability to be hashed correctly" do
      # the objects' references are not equal
      @pv1_1.should_not equal(@pv1_2)

      # the contract with hash is that pv1_1.eql?(pv1_2) implies that
      # pv1_1.hash == pv1_2.hash
      @pv1_1.should eql(@pv1_2)
      @pv1_1.hash.should == @pv1_2.hash

      # putting it all together, inserting by pv1_1 and accessing by
      # pv1_2 should succeed
      hash = {}
      hash[@pv1_1] = @pv1_1
      hash[@pv1_2].should equal(@pv1_1)
    end

  end

end
