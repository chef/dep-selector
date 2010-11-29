require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

require 'pp'

describe DepSelector::DependencyGraph do
  it "can create a package named foo" do
    dep_graph = DepSelector::DependencyGraph.new
    pkg = dep_graph.package("A")
    pkg.name.should == "A"
  end

  it "#clone should perform a deep copy" do
    pending "Elimination"
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
