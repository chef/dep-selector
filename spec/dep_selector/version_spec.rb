#
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require 'dep_selector/version'

describe DepSelector::Version do
  before do
    @v0 = DepSelector::Version.new "0.0.0"
    @v123 = DepSelector::Version.new "1.2.3"
  end

  it "should turn itself into a string" do
    @v0.to_s.should == "0.0.0"
    @v123.to_s.should == "1.2.3"
  end
  
  it "should make a round trip with its string representation" do
    a = DepSelector::Version.new(@v123.to_s)
    a.should == @v123
  end
  
  it "should transform 1.2 to 1.2.0" do
    DepSelector::Version.new("1.2").to_s.should == "1.2.0"
  end

  it "should transform 01.002.0003 to 1.2.3" do
    a = DepSelector::Version.new "01.002.0003"
    a.should == @v123
  end

  describe "when creating valid Versions" do
    good_versions = %w(1.2 1.2.3 1000.80.50000 0.300.25 001.02.00003)
    good_versions.each do |v|
      it "should accept '#{v}'" do
        DepSelector::Version.new v
      end
    end
  end

  describe "when given bogus input" do
    bad_versions = ["1.2.3.4", "1.2.a4", "1", "a", "1.2 3", "1.2 a",
                    "1 2 3", "1-2-3", "1_2_3", "1.2_3", "1.2-3"]
    the_error = DepSelector::Exceptions::InvalidVersion
    bad_versions.each do |v|
      it "should raise #{the_error} when given '#{v}'" do
        lambda { DepSelector::Version.new v }.should raise_error(the_error)
      end
    end
  end

  describe "<=>" do

    it "should equate versions 1.2 and 1.2.0" do
      DepSelector::Version.new("1.2").should == DepSelector::Version.new("1.2.0")
    end

    it "should equate version 1.04 and 1.4" do
      DepSelector::Version.new("1.04").should == DepSelector::Version.new("1.4")
    end

    it "should treat versions as numbers in the right way" do
      DepSelector::Version.new("2.0").should be < DepSelector::Version.new("11.0")
    end

    it "should sort based on the version number" do
      examples = [
                  # smaller, larger
                  ["1.0", "2.0"],
                  ["1.2.3", "1.2.4"],
                  ["1.2.3", "1.3.0"],
                  ["1.2.3", "1.3"],
                  ["1.2.3", "2.1.1"],
                  ["1.2.3", "2.1"],
                  ["1.2", "1.2.4"],
                  ["1.2", "1.3.0"],
                  ["1.2", "1.3"],
                  ["1.2", "2.1.1"],
                  ["1.2", "2.1"]
                 ]
      examples.each do |smaller, larger|
        sm = DepSelector::Version.new(smaller)
        lg = DepSelector::Version.new(larger)
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should sort an array of versions" do
      a = %w{0.0.0 0.0.1 0.1.0 0.1.1 1.0.0 1.1.0 1.1.1}.map do |s|
        DepSelector::Version.new(s)
      end
      got = a.sort.map {|v| v.to_s }
      got.should == %w{0.0.0 0.0.1 0.1.0 0.1.1 1.0.0 1.1.0 1.1.1}
    end

    it "should sort an array of versions, part 2" do
      a = %w{9.8.7 1.0.0 1.2.3 4.4.6 4.5.6 0.8.6 4.5.5 5.9.8 3.5.7}.map do |s|
        DepSelector::Version.new(s)
      end
      got = a.sort.map { |v| v.to_s }
      got.should == %w{0.8.6 1.0.0 1.2.3 3.5.7 4.4.6 4.5.5 4.5.6 5.9.8 9.8.7}
    end

    describe "comparison examples" do
      [ 
       [ "0.0.0", :>, "0.0.0", false ],
       [ "0.0.0", :>=, "0.0.0", true ],
       [ "0.0.0", :==, "0.0.0", true ],
       [ "0.0.0", :<=, "0.0.0", true ],
       [ "0.0.0", :<, "0.0.0", false ],
       [ "0.0.0", :>, "0.0.1", false ],
       [ "0.0.0", :>=, "0.0.1", false ],
       [ "0.0.0", :==, "0.0.1", false ],
       [ "0.0.0", :<=, "0.0.1", true ],
       [ "0.0.0", :<, "0.0.1", true ],
       [ "0.0.1", :>, "0.0.1", false ],
       [ "0.0.1", :>=, "0.0.1", true ],
       [ "0.0.1", :==, "0.0.1", true ],
       [ "0.0.1", :<=, "0.0.1", true ],
       [ "0.0.1", :<, "0.0.1", false ],
       [ "0.1.0", :>, "0.1.0", false ],
       [ "0.1.0", :>=, "0.1.0", true ],
       [ "0.1.0", :==, "0.1.0", true ],
       [ "0.1.0", :<=, "0.1.0", true ],
       [ "0.1.0", :<, "0.1.0", false ],
       [ "0.1.1", :>, "0.1.1", false ],
       [ "0.1.1", :>=, "0.1.1", true ],
       [ "0.1.1", :==, "0.1.1", true ],
       [ "0.1.1", :<=, "0.1.1", true ],
       [ "0.1.1", :<, "0.1.1", false ],
       [ "1.0.0", :>, "1.0.0", false ],
       [ "1.0.0", :>=, "1.0.0", true ],
       [ "1.0.0", :==, "1.0.0", true ],
       [ "1.0.0", :<=, "1.0.0", true ],
       [ "1.0.0", :<, "1.0.0", false ],
       [ "1.0.0", :>, "0.0.1", true ],
       [ "1.0.0", :>=, "1.9.2", false ],
       [ "1.0.0", :==, "9.7.2", false ],
       [ "1.0.0", :<=, "1.9.1", true ],
       [ "1.0.0", :<, "1.9.0", true ],
       [ "1.2.2", :>, "1.2.1", true ],
       [ "1.2.2", :>=, "1.2.1", true ],
       [ "1.2.2", :==, "1.2.1", false ],
       [ "1.2.2", :<=, "1.2.1", false ],
       [ "1.2.2", :<, "1.2.1", false ]
      ].each do |spec|
        it "(#{spec.first(3).join(' ')}) should be #{spec[3]}" do
          got = DepSelector::Version.new(spec[0]).send(spec[1],
                                                DepSelector::Version.new(spec[2]))
          got.should == spec[3]
        end
      end
    end
  end

  it "should implement the ability to be hashed correctly" do
    v1_1 = DepSelector::Version.new("1.0.0")
    v1_2 = DepSelector::Version.new("1.0.0")

    # the objects' references are not equal
    v1_1.should_not equal(v1_2)

    # the contract with hash is that v1_1.eql?(v1_2) implies that
    # v1_1.hash == v1_2.hash
    v1_1.should eql(v1_2)
    v1_1.hash.should == v1_2.hash

    # putting it all together, inserting by v1_1 and accessing by v1_2
    # should succeed
    hash = {}
    hash[v1_1] = v1_1
    hash[v1_2].should equal(v1_1)
  end

end

