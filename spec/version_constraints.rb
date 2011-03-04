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

module VersionConstraints 
  Simple_cookbook_version_constraint =
    [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
     {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
     {"key"=>["B", "1.0.0"], "value"=>{}},
     {"key"=>["B", "2.0.0"], "value"=>{}},
     {"key"=>["C", "1.0.0"], "value"=>{}},
    ]

  SimpleProblem_1_soluble = {
    :desc => "Simple soluble problem, one solution",
    :version_constraint => Simple_cookbook_version_constraint,
    :runlist_constraint => [
                            ["A"],
                            ["B", "= 1.0.0"]
                           ],
    :solution =>  {'A'=>'2.0.0', 'B'=>'1.0.0', 'C'=>'1.0.0'}
  }
  
  SimpleProblem_2_insoluble = {
    :desc => "fails to solve a simple, unsatisfiable set of constraints",
    :version_constraint => Simple_cookbook_version_constraint,
    :runlist_constraint => [
                            ["A", "= 1.0.0"],
                            ["B", "= 1.0.0"]
                           ],
    :solution =>  {'A'=>'1.0.0', 'B'=>'1.0.0', 'C'=>'1.0.0'}
  }
   
  Simple_cookbook_version_constraint_2 =
    [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>"= 2.0.0"}},
     {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
     {"key"=>["B", "1.0.0"], "value"=>{}},
     {"key"=>["B", "2.0.0"], "value"=>{}},
     {"key"=>["C", "1.0.0"], "value"=>{}},
     {"key"=>["C", "2.0.0"], "value"=>{}},
     {"key"=>["C", "3.0.0"], "value"=>{}}
    ]

  SimpleProblem_3_soluble = {
    :desc => "solves problem 3 constraints",
    :version_constraint => Simple_cookbook_version_constraint_2,
    :runlist_constraint => [
                            ["A"],
                            ["B", "= 2.0.0"]
                           ],
    :solution => { 'A'=>'1.0.0', 'B'=>'2.0.0', 'C'=>'2.0.0'}
  }




  Simple_cookbook_version_constraint_3 =
    [{"key"=>["A", "1.0.0"], "value"=>{"B"=>">= 1.0.0"}},
     {"key"=>["B", "1.0.0"], "value"=>{}},
     {"key"=>["B", "2.0.0"], "value"=>{}},
    ]

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

  Moderate_cookbook_version_constraint_2 =
    [{"key"=>["A", "1.0"], "value"=>{"C"=>"< 4.0"}},
     {"key"=>["B", "1.0"], "value"=>{"C"=>"< 3.0"}},
     {"key"=>["C", "2.0"], "value"=>{"D"=>"> 1.0", "F"=>">= 0.0.0"}},
     {"key"=>["C", "3.0"], "value"=>{"D"=>"> 2.0", "E"=>">= 0.0.0"}},
     {"key"=>["D", "1.1"], "value"=>{}},
     {"key"=>["D", "2.1"], "value"=>{}},
     {"key"=>["E", "1.0"], "value"=>{}},
     {"key"=>["F", "1.0"], "value"=>{}},
    ]
end
