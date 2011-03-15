require 'benchmark'

require File.expand_path(File.join(File.dirname(__FILE__), 'spec','spec_helper'))

def my_verify_solution(observed, expected)
  versions = expected.inject({}){|acc, elt| acc[elt.first]=DepSelector::Version.new(elt.last) ; acc}
  if (observed != versions) 
    raise "Failed Comparison"
  end
end

Moderate_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>">= 2.0.0"}},
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
   {"key"=>["D", "4.0.0"], "value"=>{}} 
  ]




def test
  dep_graph = DepSelector::DependencyGraph.new
  setup_constraint(dep_graph, Moderate_cookbook_version_constraint)
  selector = DepSelector::Selector.new(dep_graph)
  solution_constraints =
    setup_soln_constraints(dep_graph,
                           [
                            ["A"],
                            ["C", "= 4.0"],
                           ])
  soln = selector.find_solution(solution_constraints)
  
 my_verify_solution(soln,
                  { "A" => "1.0.0",
                    "B" => "2.0.0",
                    "C" => "4.0.0",
                    "D" => "4.0.0"
                  })
end


def run 
  x = Benchmark.measure do
    10000.times do 
      test
    end
  end
  puts x
end

run
