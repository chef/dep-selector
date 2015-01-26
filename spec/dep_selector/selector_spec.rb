require File.expand_path(File.join(File.dirname(__FILE__), '..','spec_helper'))

simple_cookbook_version_constraint =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}},
  ]

simple_cookbook_version_constraint_2 =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 2.0.0", "C"=>"= 2.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 1.0.0", "C"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{}},
   {"key"=>["B", "2.0.0"], "value"=>{}},
   {"key"=>["C", "1.0.0"], "value"=>{}},
   {"key"=>["C", "2.0.0"], "value"=>{}},
   {"key"=>["C", "3.0.0"], "value"=>{}}
  ]

# simple_cookbook_version_constraint_3 =
#   [{"key"=>["A", "1.0.0"], "value"=>{"B"=>">= 1.0.0"}},
#    {"key"=>["B", "1.0.0"], "value"=>{}},
#    {"key"=>["B", "2.0.0"], "value"=>{}},
#   ]

moderate_cookbook_version_constraint =
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

# moderate_cookbook_version_constraint_2 =
#   [{"key"=>["A", "1.0"], "value"=>{"C"=>"< 4.0"}},
#    {"key"=>["B", "1.0"], "value"=>{"C"=>"< 3.0"}},
#    {"key"=>["C", "2.0"], "value"=>{"D"=>"> 1.0", "F"=>">= 0.0.0"}},
#    {"key"=>["C", "3.0"], "value"=>{"D"=>"> 2.0", "E"=>">= 0.0.0"}},
#    {"key"=>["D", "1.1"], "value"=>{}},
#    {"key"=>["D", "2.1"], "value"=>{}},
#    {"key"=>["E", "1.0"], "value"=>{}},
#    {"key"=>["F", "1.0"], "value"=>{}},
#   ]

moderate_cookbook_version_constraint_3 =
  [{"key"=>["a", "1.0"], "value"=>{"c"=>"< 4.0"}}, 
   {"key"=>["b", "1.0"], "value"=>{"c"=>"< 3.0"}},
   {"key"=>["c", "2.0"], "value"=>{"d"=>"> 1.0", "f"=>nil}},
   {"key"=>["c", "3.0"], "value"=>{"d"=>"> 2.0", "e"=>nil}},
   {"key"=>["d", "1.1"], "value"=>{}},
   {"key"=>["d", "2.1"], "value"=>{}},
   {"key"=>["e", "1.0"], "value"=>{}},
   {"key"=>["f", "1.0"], "value"=>{}},
   {"key"=>["g", "1.0"], "value"=>{"d"=>"> 5.0"}},
   {"key"=>["n", "1.1"], "value"=>{}},
   {"key"=>["n", "1.2"], "value"=>{}},
   {"key"=>["n", "1.10"], "value"=>{}},
   {"key"=>["depends_on_nosuch", "1.0"], "value"=>{"nosuch"=>nil}}
  ]


# big_cookbook_version_constraint_0 = 
#   [{"key"=>["A", "1.0"], "value"=>{"B"=>"= 1.0"}}]
# 
# big_cookbook_version_constraint_1 = 
#   [{"key"=>["A", "0.0.0"], "value"=>{"B"=>"<= 0.0.0"}},
#    {"key"=>["B", "0.0.0"], "value"=>{}},
#    {"key"=>["C", "0.0.0"], "value"=>{}},
#    {"key"=>["D", "0.0.0"], "value"=>{"E"=>"<= 0.0.0", "F"=>"<= 0.0.0", "C"=>"<= 0.0.0"}},
#    {"key"=>["E", "0.0.0"], "value"=>{}},
#    {"key"=>["F", "0.0.0"], "value"=>{}},
#    {"key"=>["G", "0.0.0"], "value"=>{}},
#    {"key"=>["H", "0.0.0"], "value"=>{}},
#    {"key"=>["I", "0.0.0"], "value"=>{}},
#    {"key"=>["I", "1.0.0"], "value"=>{}},
#    {"key"=>["J", "0.0.0"], "value"=>{"B"=>"<= 0.0.0"}},
#    {"key"=>["K", "0.0.0"], "value"=>{}},
#    {"key"=>["K", "1.0.0"], "value"=>{}},
#    {"key"=>["L", "0.0.0"], "value"=>{}},
#    {"key"=>["M", "0.0.0"], "value"=>{}},
#    {"key"=>["N", "0.0.0"], "value"=>{}},
#    {"key"=>["O", "0.0.0"], "value"=>{}},
#    {"key"=>["P", "0.0.0"], "value"=>{}},
#    {"key"=>["P", "1.0.0"], "value"=>{}},
#    {"key"=>["Q", "0.0.0"], "value"=>{}},
#    {"key"=>["Q", "1.0.0"], "value"=>{"R"=>"<= 0.0.0"}},
#    {"key"=>["R", "0.0.0"], "value"=>{}},
#    {"key"=>["S", "0.0.0"], "value"=>{"R"=>"<= 0.0.0"}},
#    {"key"=>["T", "0.0.0"], "value"=>{}},
#    {"key"=>["U", "0.0.0"], "value"=>{"O"=>"<= 0.0.0"}},
#    {"key"=>["V", "0.0.0"], "value"=>{}},
#    {"key"=>["W", "0.0.0"], "value"=>{}},
#    {"key"=>["X", "0.0.0"], "value"=>{}},
#    {"key"=>["Y", "0.0.0"], "value"=>{}},
#    {"key"=>["Y", "1.0.0"], "value"=>{}},
#    {"key"=>["Z", "0.0.0"], "value"=>{}},
#    {"key"=>["Z", "1.0.0"], "value"=>{"C"=>"<= 0.0.0"}},
#    {"key"=>["AA", "0.0.0"],
#      "value"=>
#      { "A"=>"<= 0.0.0",
#        "C"=>"<= 0.0.0",
#        "D"=>"<= 0.0.0",
#        "G"=>"<= 0.0.0",
#        "H"=>"<= 0.0.0",
#        "I"=>"<= 1.0.0",
#        "J"=>"<= 0.0.0",
#        "K"=>"<= 1.0.0",
#        "L"=>"<= 0.0.0"}}]

big_cookbook_version_constraint_2 =
  [{"key"=>["A", "0.0"], "value"=>{"B"=>"<= 0.0", "C"=>"<= 12.0"}},
   {"key"=>["A", "1.0"], "value"=>{"B"=>"<= 0.0", "C"=>"<= 12.0"}},
   {"key"=>["B", "0.0"], "value"=>{"D"=>"<= 0.0", "E"=>"<= 0.0"}},
   {"key"=>["C", "0.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "J"=>"<= 0.0",
       "I"=>"<= 2.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "1.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "2.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "3.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "4.0"],
     "value"=>
   {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "5.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "6.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
 {"key"=>["C", "7.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "8.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "9.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "10.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "11.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["C", "12.0"],
     "value"=>
     {"F"=>"<= 1.0",
       "G"=>"<= 2.0",
       "H"=>"<= 0.0",
       "E"=>"<= 0.0",
       "I"=>"<= 2.0",
       "J"=>"<= 0.0",
       "K"=>"<= 1.0"}},
   {"key"=>["D", "0.0"], "value"=>{}},
   {"key"=>["E", "0.0"], "value"=>{}},
   {"key"=>["F", "0.0"], "value"=>{"A"=>"<= 1.0"}},
   {"key"=>["F", "1.0"], "value"=>{"A"=>"<= 1.0"}},
   {"key"=>["G", "0.0"], "value"=>{"E"=>"<= 0.0", "C"=>"<= 12.0"}},
   {"key"=>["G", "1.0"], "value"=>{"E"=>"<= 0.0", "C"=>"<= 12.0"}},
   {"key"=>["G", "2.0"], "value"=>{"E"=>"<= 0.0", "C"=>"<= 12.0"}},
   {"key"=>["H", "0.0"], "value"=>{"L"=>"<= 1.0"}},
   {"key"=>["I", "0.0"], "value"=>{"J"=>"<= 0.0"}},
   {"key"=>["I", "1.0"], "value"=>{"J"=>"<= 0.0"}},
   {"key"=>["I", "2.0"], "value"=>{"J"=>"<= 0.0"}},
   {"key"=>["J", "0.0"], "value"=>{"T"=>"<= 0.0", "A"=>"<= 1.0"}},
   {"key"=>["K", "0.0"], "value"=>{}},
   {"key"=>["K", "1.0"], "value"=>{}},
   {"key"=>["L", "0.0"],
     "value"=>{"M"=>"<= 0.0", "B"=>"<= 0.0", "N"=>"<= 8.0", "C"=>"<= 12.0"}},
   {"key"=>["L", "1.0"],
     "value"=>{"M"=>"<= 0.0", "B"=>"<= 0.0", "C"=>"<= 12.0", "N"=>"<= 8.0"}},
   {"key"=>["M", "0.0"], "value"=>{"O"=>"<= 0.0", "C"=>"<= 12.0"}},
   {"key"=>["N", "0.0"],
     "value"=>
     {"P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["N", "1.0"],
     "value"=>
     {"P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["N", "2.0"],
     "value"=>
     {"P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["N", "3.0"],
     "value"=>
     {"P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["N", "4.0"],
     "value"=>
     {"P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["N", "5.0"],
     "value"=>
     {"O"=>"<= 0.0",
       "P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["N", "6.0"],
     "value"=>
     {"O"=>"<= 0.0",
       "P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["N", "7.0"],
     "value"=>
     {"O"=>"<= 0.0",
       "P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["N", "8.0"],
     "value"=>
     {"O"=>"<= 0.0",
       "P"=>"<= 0.0",
       "Q"=>"<= 0.0",
       "R"=>"<= 6.0",
       "S"=>"<= 2.0",
       "J"=>"<= 0.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["O", "0.0"], "value"=>{}},
   {"key"=>["P", "0.0"],
     "value"=>{"E"=>"<= 0.0", "A"=>"<= 1.0", "C"=>"<= 12.0"}},
   {"key"=>["Q", "0.0"], "value"=>{"A"=>"<= 1.0"}},
   {"key"=>["R", "0.0"],
     "value"=>
     {"G"=>"<= 2.0",
       "Q"=>"<= 0.0",
       "E"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["R", "1.0"],
     "value"=>
     {"G"=>"<= 2.0",
       "Q"=>"<= 0.0",
       "E"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["R", "2.0"],
     "value"=>
     {"G"=>"<= 2.0",
       "Q"=>"<= 0.0",
       "E"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["R", "3.0"],
     "value"=>
     {"G"=>"<= 2.0",
       "Q"=>"<= 0.0",
       "E"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["R", "4.0"],
     "value"=>
     {"G"=>"<= 2.0",
       "Q"=>"<= 0.0",
       "E"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["R", "5.0"],
     "value"=>
     {"G"=>"<= 2.0",
       "Q"=>"<= 0.0",
       "E"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["R", "6.0"],
     "value"=>
     {"G"=>"<= 2.0",
       "Q"=>"<= 0.0",
       "E"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0"}},
   {"key"=>["S", "0.0"], "value"=>{"H"=>"<= 0.0", "E"=>"<= 0.0"}},
   {"key"=>["S", "1.0"], "value"=>{"H"=>"<= 0.0", "E"=>"<= 0.0"}},
   {"key"=>["S", "2.0"], "value"=>{"H"=>"<= 0.0", "E"=>"<= 0.0"}},
   {"key"=>["T", "0.0"], "value"=>{}},
   {"key"=>["U", "0.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "1.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "2.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "3.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "4.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "5.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "6.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "7.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "8.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "9.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "10.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["U", "11.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["V", "0.0"],
     "value"=>
     {"W"=>"<= 0.0",
       "X"=>"<= 0.0",
       "E"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0",
       "Y"=>"<= 0.0"}},
   {"key"=>["V", "1.0"],
     "value"=>
     {"W"=>"<= 0.0",
       "X"=>"<= 0.0",
       "E"=>"<= 0.0",
       "J"=>"<= 0.0",
       "L"=>"<= 1.0",
       "A"=>"<= 1.0",
       "C"=>"<= 12.0",
       "Y"=>"<= 0.0"}},
   {"key"=>["W", "0.0"], "value"=>{}},
   {"key"=>["X", "0.0"], "value"=>{"C"=>"<= 12.0"}},
   {"key"=>["Y", "0.0"],
     "value"=>{"E"=>"<= 0.0", "A"=>"<= 1.0", "C"=>"<= 12.0"}},
   {"key"=>["Z", "0.0"], "value"=>{}},
   {"key"=>["AA", "0.0"], "value"=>{"C"=>"<= 12.0"}},
   {"key"=>["AB", "0.0"], "value"=>{"E"=>"<= 0.0"}},
   {"key"=>["AC", "0.0"], "value"=>{"E"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["AD", "0.0"], "value"=>{}},
   {"key"=>["AE", "0.0"], "value"=>{"E"=>"<= 0.0"}},
   {"key"=>["AF", "0.0"],
     "value"=>{"X"=>"<= 0.0", "E"=>"<= 0.0", "C"=>"<= 12.0"}},
   {"key"=>["AG", "0.0"], "value"=>{}},
   {"key"=>["AH", "0.0"], "value"=>{"E"=>"<= 0.0"}},
   {"key"=>["AI", "0.0"], "value"=>{"X"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["AI", "1.0"], "value"=>{"X"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["AI", "2.0"], "value"=>{"X"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["AI", "3.0"], "value"=>{"X"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["AI", "4.0"], "value"=>{"X"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["AI", "5.0"], "value"=>{"X"=>"<= 0.0", "U"=>"<= 11.0"}},
   {"key"=>["AJ", "0.0"],
     "value"=>
     {"AK"=>"<= 2.0",
       "E"=>"<= 0.0",
       "J"=>"<= 0.0",
       "AI"=>"<= 5.0",
       "U"=>"<= 11.0",
       "Y"=>"<= 0.0"}},
   {"key"=>["AK", "0.0"],
     "value"=>{"J"=>"<= 0.0", "U"=>"<= 11.0", "AI"=>"<= 5.0"}},
   {"key"=>["AK", "1.0"],
     "value"=>{"J"=>"<= 0.0", "AI"=>"<= 5.0", "U"=>"<= 11.0"}},
   {"key"=>["AK", "2.0"],
     "value"=>{"J"=>"<= 0.0", "AI"=>"<= 5.0", "U"=>"<= 11.0"}},
   {"key"=>["AL", "0.0"],
     "value"=>
     {"A"=>"<= 1.0",
       "U"=>"<= 11.0",
       "H"=>"<= 0.0",
       "V"=>"<= 1.0",
       "Z"=>"<= 0.0",
       "AA"=>"<= 0.0",
       "AB"=>"<= 0.0",
       "AC"=>"<= 0.0",
       "AD"=>"<= 0.0",
       "X"=>"<= 0.0",
       "AE"=>"<= 0.0",
       "O"=>"<= 0.0",
       "M"=>"<= 0.0",
       "AF"=>"<= 0.0",
       "AG"=>"<= 0.0",
       "C"=>"<= 12.0",
       "B"=>"<= 0.0",
       "N"=>"<= 8.0",
       "Y"=>"<= 0.0",
       "AH"=>"<= 0.0",
       "AI"=>"<= 5.0",
       "Q"=>"<= 0.0",
       "J"=>"<= 0.0",
       "AJ"=>"<= 0.0"}}]

padding_packages =
  [{"key"=>["padding1", "1.0"], "value"=>{}},
   {"key"=>["padding2", "1.0"], "value"=>{}}
  ]

dependencies_whose_constraints_match_no_versions =
  [{"key"=>["A", "1.0"], "value"=>{}},
   {"key"=>["B", "1.0"], "value"=>{"A"=>"> 1.0"}},
   {"key"=>["C", "1.0"], "value"=>{"B"=>nil}},
   *padding_packages
  ]

dependency_on_non_existent_package =
  [{"key"=>["depends_on_nosuch", "1.0.0"], "value"=>{"nosuch"=>"= 2.0.0"}},
   {"key"=>["transitive_dep_on_nosuch", "1.0.0"], "value"=>{"depends_on_nosuch"=>nil}},
   *padding_packages
  ]

satisfiable_circular_dependency_graph =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 1.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{"A"=>"= 1.0.0"}}
  ]

unsatisfiable_circular_dependency_graph =
  [{"key"=>["A", "1.0.0"], "value"=>{"B"=>"= 1.0.0"}},
   {"key"=>["A", "2.0.0"], "value"=>{"B"=>"= 2.0.0"}},
   {"key"=>["B", "1.0.0"], "value"=>{"A"=>"= 2.0.0"}},
   {"key"=>["B", "2.0.0"], "value"=>{"A"=>"= 1.0.0"}},
   *padding_packages
  ]

describe DepSelector::Selector do
  
  describe "find_solution" do

    it "a simple set of constraints and includes transitive dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "a simple set of constraints and doesn't include unnecessary dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 2.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0"
                      })
    end

    it "a simple set of constraints and does not include unnecessary assignments" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 2.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0"
                      })
    end

    it "and indicates which solution constraint makes the system unsatisfiable if there is no solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint_2)
      setup_constraint(dep_graph, padding_packages)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["C", "= 3.0.0"],
                                ["padding1"]
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == unsatisfiable_solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('C')]
      end
    end

    it "can solve a moderately complex system with a unique solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["C", "= 4.0"],
                                ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "2.0.0",
                        "C" => "4.0.0",
                        "D" => "4.0.0"
                      })
    end

    it "should find a solution regardless of the dependency graph having a package with a dependency constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "should fail to find a solution when one or more solution constraints are invalid and respect the authoritative list of extant packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      setup_constraint(dep_graph, padding_packages)
      selector = DepSelector::Selector.new(dep_graph)
      invalid_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                # these don't exist
                                ["nosuch1", "> 1.0.0"],
                                ["nosuch2", "> 1.0.0"],
                                # these match no versions
                                ["A", "> 1.0"],
                                ["B", "> 1.0"],
                                # this is passed into find_solutions as valid but will have no versions
                                ["really_does_exist"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(invalid_solution_constraints, [dep_graph.package("really_does_exist")])
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::InvalidSolutionConstraints => isc
        # TODO: explain in commit message, side effects in the test mean that
        # we can't tell the difference between packages with no versions
        # created by test setup vs. those passed in w/ the "valid packages"
        # argument to #find_solution; this shouldn't matter though because a
        # package w/ zero versions should not occur in correct usage
        isc.non_existent_packages.should == [
                                             invalid_solution_constraints[1],
                                             invalid_solution_constraints[2],
                                             invalid_solution_constraints[5]
                                            ]
        isc.constrained_to_no_versions.should == [
                                                  invalid_solution_constraints[3],
                                                  invalid_solution_constraints[4]
                                                 ]
      end
    end

    it "should fail to find a solution when a solution constraint's dependency is constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["B"],
                                ["padding2"],
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == unsatisfiable_solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('A')]
      end
    end

    it "should fail to find a solution when a solution constraint's transitive dependency is constrained to a range that includes no packages" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependencies_whose_constraints_match_no_versions)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["C"],
                                ["padding2"],
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == unsatisfiable_solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('A')]
      end
    end

    it "should find a solution if one can be found regardless of invalid dependencies" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, simple_cookbook_version_constraint)
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                                ["B", "= 1.0.0"]
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "2.0.0",
                        "B" => "1.0.0",
                        "C" => "1.0.0"
                      })
    end

    it "should fail to find a solution if a package with an invalid dependency is a direct dependency of one of the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["depends_on_nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
        nse.disabled_non_existent_packages.should == [dep_graph.package('nosuch')]
        nse.disabled_most_constrained_packages.should == []
      end
    end

    it "should respect the authoritative list of extant packages in the case of failure" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["depends_on_nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints, [dep_graph.package('nosuch')])
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('nosuch')]
      end
    end

    it "should fail to find a solution if a package with an invalid dependency is a transitive dependency of one of the solution constraints" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, dependency_on_non_existent_package)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["transitive_dep_on_nosuch"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
        nse.disabled_non_existent_packages.should == [dep_graph.package('nosuch')]
        nse.disabled_most_constrained_packages.should == []
      end
    end

    it "should solve a circular dependency graph that has a valid solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, satisfiable_circular_dependency_graph)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["A"],
                               ])
      soln = selector.find_solution(solution_constraints)

      verify_solution(soln,
                      { "A" => "1.0.0",
                        "B" => "1.0.0"
                      })
    end

    it "should fail to find a solution for (and not infinitely recurse on) a dependency graph that does not have a valid solution" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, unsatisfiable_circular_dependency_graph)
      selector = DepSelector::Selector.new(dep_graph)
      solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["padding1"],
                                ["A", "= 1.0.0"],
                                ["padding2"]
                               ])
      begin
        selector.find_solution(solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.unsatisfiable_solution_constraint.should == solution_constraints[1]
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('B')]
      end
    end

    it "should indicate that the problematic package is the dependency that is constrained to no versions" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint_3)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["g"]
                               ])
      begin
        selector.find_solution(unsatisfiable_solution_constraints)
        fail "Should have failed to find a solution"
      rescue DepSelector::Exceptions::NoSolutionExists => nse
        nse.message.should == "Unable to satisfy constraints on package d due to solution constraint (g >= 0.0.0). Solution constraints that may result in a constraint on d: [(g = 1.0.0) -> (d > 5.0.0)]"
        nse.disabled_non_existent_packages.should == []
        nse.disabled_most_constrained_packages.should == [dep_graph.package('d')]
      end
    end

    it "solves moderately complex dependency graph #3" do
      dep_graph = DepSelector::DependencyGraph.new
      setup_constraint(dep_graph, moderate_cookbook_version_constraint_3)
      selector = DepSelector::Selector.new(dep_graph)
      unsatisfiable_solution_constraints =
        setup_soln_constraints(dep_graph,
                               [
                                ["b", "= 1.0"],
                                ["a", "= 1.0"],
                               ])
      soln = selector.find_solution(unsatisfiable_solution_constraints)

      verify_solution(soln,
                      { "a" => "1.0.0",
                        "b" => "1.0.0",
                        "c" => "2.0.0",
                        "d" => "2.1.0",
                        "f" => "1.0.0",
                      })
    end
  end
  
  it "solves moderately complex dependency graph #3 and times out", :volatile do
    # This test does not reliably trigger timeout.
    pending("test unreliable, investigate")
    dep_graph = DepSelector::DependencyGraph.new
    setup_constraint(dep_graph, big_cookbook_version_constraint_2)
    selector = DepSelector::Selector.new(dep_graph, 0.001)
      constraints =
      setup_soln_constraints(dep_graph,
                             [["A"], ["B"], ["C"], ["N"], ["R"], ["AL"] ])
    expect do
      selector.find_solution(constraints)
    end.to raise_error(DepSelector::Exceptions::TimeBoundExceeded)
    
  end

  # TODO [cw,2011/2/4]: Add a test for a set of solution constraints
  # that contains multiple restrictions on the same package. Do the
  # same for a PackageVersion that has several Dependencies on the
  # same package, some satisfiable, some not.

end
