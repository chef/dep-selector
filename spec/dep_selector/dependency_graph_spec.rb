require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

require 'pp'

simple_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}}]


complex_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{"D"=>">= 1.0.0"}},
   {"key"=>["C", "2.0.0"], "value"=>{"D"=>">= 2.0.0"}},
   {"key"=>["C", "3.0.0"], "value"=>{"D"=>">= 3.0.0"}},
   {"key"=>["C", "4.0.0"], "value"=>{"D"=>">= 4.0.0"}},
   {"key"=>["D", "1.0.0"], "value"=>{}},
   {"key"=>["D", "2.0.0"], "value"=>{}},
   {"key"=>["D", "3.0.0"], "value"=>{}},
   {"key"=>["D", "4.0.0"], "value"=>{}},
]

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
