
module VersionConstraints 
  Simple_cookbook_version_constraint =
    [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
     {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
     {"key"=>["B", "1.0.0"], "value"=>{}},
     {"key"=>["B", "2.0.0"], "value"=>{}},
     {"key"=>["C", "1.0.0"], "value"=>{}},
    ]
  
  Simple_cookbook_version_constraint_2 =
    [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>"= 2.0.0"}},
     {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
     {"key"=>["B", "1.0.0"], "value"=>{}},
     {"key"=>["B", "2.0.0"], "value"=>{}},
     {"key"=>["C", "1.0.0"], "value"=>{}},
     {"key"=>["C", "2.0.0"], "value"=>{}},
     {"key"=>["C", "3.0.0"], "value"=>{}}
    ]

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
