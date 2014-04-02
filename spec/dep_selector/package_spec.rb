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
require 'dep_selector/package'
require 'dep_selector/version'

describe DepSelector::Package do

  before do
    @dep_graph = DepSelector::DependencyGraph.new
    @test_pkg1 = DepSelector::Package.new(@dep_graph, "test_pkg")
  end

  describe "[]" do

    context "when using dep-selector's version and constraint types" do

      before do
        @tp1v1_0 = @test_pkg1.add_version(DepSelector::Version.new("1.0.0"))
        @tp1v1_1 = @test_pkg1.add_version(DepSelector::Version.new("1.1.0"))
        @tp1v2_0 = @test_pkg1.add_version(DepSelector::Version.new("2.0.0"))
      end

      it "should select the correct PackageVersion given a Version" do
        @test_pkg1[DepSelector::Version.new("1.0.0")].should == @tp1v1_0
      end

      it "should select all PackageVersions that match a given constraint" do
        @test_pkg1[DepSelector::VersionConstraint.new("= 1.0.0")].should == [
                                                                             @tp1v1_0
                                                                            ]
        @test_pkg1[DepSelector::VersionConstraint.new("~> 1.0")].should == [
                                                                            @tp1v1_0,
                                                                            @tp1v1_1
                                                                           ]
        @test_pkg1[DepSelector::VersionConstraint.new("> 1.0.0")].should == [
                                                                             @tp1v1_1,
                                                                             @tp1v2_0
                                                                            ]
      end
    end

    context "when using duck types of version and constraint objects" do

      let(:version_1_0_0) { double("A version type") }
      let(:constraint) { double("A constraint type") }

      it "selects versions that match the constraints" do
        constraint.stub(:respond_to?).with(:include?).and_return(true)
        constraint.should_receive(:include?).with(version_1_0_0).and_return(true)

        test_pkg_version_1_0_0 = @test_pkg1.add_version(version_1_0_0)
        @test_pkg1[constraint].should == [test_pkg_version_1_0_0]
      end


    end

  end

  describe "valid?" do
    it "should return false if the package has no versions" do
      @test_pkg1.valid?.should == false
    end

    it "should return true if the package has at least one version" do
      @test_pkg1.add_version(DepSelector::Version.new("1.0.0"))
      @test_pkg1.valid?.should == true
    end
  end
end

