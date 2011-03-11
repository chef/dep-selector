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

require 'dep_selector'


Base_Constraint =
  { 
  "A_001"=>{
    "1.0"=>{"B_001"=>"= 2.0"},
    "2.0"=>{"B_001"=>"= 1.0", "D_001"=>"= 1.0", "E_001"=>"= 1.0"} },
  "B_001"=> {
    "1.0"=>{"C_001"=>"= 2.0"},
    "2.0"=>{"C_001"=>"= 1.0"} },
  "C_001"=> { "1.0"=>{}, "2.0"=>{} },
  "D_001"=> { "1.0"=>{}, "2.0"=>{} },
  "E_001"=> { "1.0"=>{}, "2.0"=>{} },
}


def gen_next(base)
  base_succ = {}
  return base unless base.is_a?(Hash)
  base.each_pair do |key,value|
      if key =~ /^[A-Z]/
        base_succ[key.succ] = gen_next(value)
      else
        base_succ[key] = gen_next(value)
      end
  end
  base_succ
end

def build_ugly_constraint(base,count)
  constraint = {}
  cur = base;
  (1..count).each do |x|
    constraint.merge!(cur)
    cur = gen_next(cur)
  end
  constraint
end

def setup_constraint(dep_graph, cset)
  cset.keys.sort.each do |package_name|
    version_spec = cset[package_name]
    version_spec.keys.sort.each do |cb_version|
      dependencies = version_spec[cb_version]
      version = DepSelector::Version.new(cb_version)
      pv = dep_graph.package(package_name).add_version(version)
      dependencies.keys.sort.each do |dep_name|
        constraint_str = dependencies[dep_name]
        constraint = DepSelector::VersionConstraint.new(constraint_str)
        pv.dependencies << DepSelector::Dependency.new(dep_graph.package(dep_name), constraint)
      end
    end
  end
end

def setup_soln_constraints(dep_graph, soln_constraints)
  soln_constraints.map do |elt|
    pkg = dep_graph.package(elt.shift)
    constraint = DepSelector::VersionConstraint.new(elt.shift)
    DepSelector::SolutionConstraint.new(pkg, constraint)
  end
end

# def verify_solution(observed, expected)
#   versions = expected.inject({}){|acc, elt| acc[elt.first]=DepSelector::Version.new(elt.last) ; acc}
#   observed.should == versions
# end

def run_test_simple_ugly 
  rep_count = 500
  dep_graph = DepSelector::DependencyGraph.new
  
  ugly_constraint = build_ugly_constraint(Base_Constraint, rep_count)

  setup_constraint(dep_graph, ugly_constraint)
  selector = DepSelector::Selector.new(dep_graph)

  run_list_length = 500
  run_list = 0.upto(run_list_length-2).inject([["A_001"]]) { |acc, arr| acc << [acc.last.first.next] }

#  pp :run_list=>run_list
#  pp :ugly_constraint=>ugly_constraint

  solution_constraints =
    setup_soln_constraints(dep_graph,
                            run_list
                           )
  soln = selector.find_solution(solution_constraints)
  
#  puts soln

end
require 'benchmark'

puts Benchmark.measure { 5.times { run_test_simple_ugly } }
