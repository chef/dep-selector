Background
==========
The dep_selector gem contains the native Ruby bindings for solving
dependency graphs with Gecode. It accepts a representation of packages
and their dependencies and finds a binding of packages to versions that
satisfies desired constraints.

Installation
------------
Install the gem from Rubygems:

    gem install dep_selector

Or add it to your `Gemfile`:

```ruby
gem 'dep_selector'
```


Learn by Example
----------------

```ruby
require 'dep_selector'

# This example corresponds to the following dependency graph:
#   A has versions: 1, 2
#   B has versions: 1, 2, 3
#   C has versions: 1, 2
#   D has versions: 1, 2
#   A1 -> B=1         (v1 of package A depends on v1 of package B)
#   A2 -> B>=2, C=1   (v2 of package A depends on B at v2 or greater and v1 of C)
#   B3 -> D=1         (v3 of package B depends on v1 of package D)
#   C2 -> D=2         (v2 of package C depends on v2 of package D)

include DepSelector

# create dependency graph
dep_graph = DependencyGraph.new

# package A has versions 1 and 2
a = dep_graph.package('A')
a1 = a.add_version(Version.new('1.0.0'))Â
a2 = a.add_version(Version.new('2.0.0'))

# package B has versions 1, 2, and 3
b = dep_graph.package('B')
b1 = b.add_version(Version.new('1.0.0'))
b2 = b.add_version(Version.new('2.0.0'))
b3 = b.add_version(Version.new('3.0.0'))

# package C only has versions 1 and 2
c = dep_graph.package('C')
c1 = c.add_version(Version.new('1.0.0'))
c2 = c.add_version(Version.new('2.0.0'))

# package D only has versions 1 and 2
d = dep_graph.package('D')
d1 = d.add_version(Version.new('1.0.0'))
d2 = d.add_version(Version.new('2.0.0'))

# package A version 1 has a dependency on package B at exactly 1.0.0
# Note: Though we reference the variable b in the Dependency, packages
# do not have to be created before being referenced.
# DependencyGraph#package looks up the package based on the name or
# auto-vivifies it if it doesn't yet exist, so referring to the
# variable b or calling dep_graph.package('B') before or after b is
# assigned are all equivalent.
a1.dependencies << Dependency.new(b, VersionConstraint.new('= 1.0.0'))
a1.dependencies << Dependency.new(d, VersionConstraint.new('= 2.0.0'))

# package A version 2 has dependencies on package B >= 2.0.0 and C at exactly 1.0.0
a2.dependencies << Dependency.new(b, VersionConstraint.new('>= 2.0.0'))
a2.dependencies << Dependency.new(c, VersionConstraint.new('= 1.0.0'))

# package B version 3 has a dependency on package D at exactly 1.0.0
b3.dependencies << Dependency.new(d, VersionConstraint.new('= 1.0.0'))

# package C version 2 has a dependency on package D at exactly 2.0.0
c2.dependencies << Dependency.new(d, VersionConstraint.new('= 2.0.0'))

# create a Selector from the dependency graph
selector = Selector.new(dep_graph)

# define the solution constraints and find a solution

# simple solution: any version of A as long as B is at exactly 1.0.0
solution_constraints_1 = [
  SolutionConstraint.new(dep_graph.package('A')),
  SolutionConstraint.new(dep_graph.package('B'), VersionConstraint.new('= 1.0.0'))
]

puts selector.find_solution(solution_constraints_1)
```

This will yield a hash solution:

```ruby
{
  "A" => 1.0.0,
  "B" => 1.0.0,
  "D" => 2.0.0
}
```

Or solving the for the following solution constraints:

```ruby
# more complex solution, which uses a range constraint (>=) and
# demonstrates the assignment of induced transitive dependencies
solution_constraints_2 = [
  SolutionConstraint.new(dep_graph.package('A')),
  SolutionConstraint.new(dep_graph.package('B'), VersionConstraint.new('>= 2.1'))
]
puts selector.find_solution(solution_constraints_2)
```

yields

```ruby
{
  "A" => 2.0.0,
  "B" => 3.0.0,
  "D" => 1.0.0,
  "C" => 1.0.0
}
```

But not all (dependency graph, solution constraint) systems are satisfiable,
so we must return useful error information:

```ruby
# When the solution constraints are unsatisfiable, a NoSolutionExists
# exception is raised. It identifies what the first solution
# constraint that makes the system unsatisfiable is. It also
# identifies the package(s) (either direct solution constraints or
# induced dependencies) whose constraints caused the
# unsatisfiability. The exception's message contains the name of one
# of the packages, as well as paths through the dependency graph that
# result in constraints on the package to hint at places to debug.
unsatisfiable_solution_constraints_1 = [
  SolutionConstraint.new(dep_graph.package('B'), VersionConstraint.new('= 3.0.0')),
  SolutionConstraint.new(dep_graph.package('C'), VersionConstraint.new('= 2.0.0'))
]

# Note that package D is identified as the most constrained package
# and the paths from from solution constraints to constraints on D are
# returned in the message
begin
  selector.find_solution(unsatisfiable_solution_constraints_1)
rescue Exceptions::NoSolutionExists => nse
  puts nse.message
end
```

yields

```text
Unable to satisfy constraints on package D due to solution constraint (C = 2.0.0). Solution constraints that may result in a constraint on D: [(B = 3.0.0) -> (D = 1.0.0)], [(C = 2.0.0) -> (D = 2.0.0)]
```

Another cause for unsatisfiability is a dependency on a non-existent package:

```ruby
# Now, let's create a package, depends_on_nosuch, that has a
# dependency on a non-existent package, nosuch, and see that nosuch is
# identified as the problematic package. Note that because Package
# objects are auto-vivified by DependencyGraph#Package, non-existent
# packages are any packages that have no versions.
depends_on_nosuch = dep_graph.package('depends_on_nosuch')
depends_on_nosuch_v1 = depends_on_nosuch.add_version(Version.new('1.0'))
depends_on_nosuch_v1.dependencies << Dependency.new(dep_graph.package('nosuch'))

unsatisfiable_solution_constraints_2 = [ SolutionConstraint.new(depends_on_nosuch) ]

# Note that package D is identified as the most constrained package
# and the paths from from solution constraints to constraints on D are
# returned in the message
begin
  selector.find_solution(unsatisfiable_solution_constraints_2)
rescue Exceptions::NoSolutionExists => nse
  puts nse.message
end
```

yields

```text
Unable to satisfy constraints on package nosuch, which does not exist, due to solution constraint (depends_on_nosuch >= 0.0.0). Solution constraints that may result in a constraint on nosuch: [(depends_on_nosuch = 1.0.0) -> (nosuch >= 0.0.0)]
```

DepSelector also raises an exception if there are invalid solution constraints:

```ruby
# Invalid solution constraints are those that reference a non-existent
# package, or constrain an extant package to no versions. All invalid
# solution constraints are raised in an InvalidSolutionConstraints
# exception.
invalid_solution_constraints = [
  SolutionConstraint.new(dep_graph.package('nosuch')),
  SolutionConstraint.new(dep_graph.package('nosuch2')),
  SolutionConstraint.new(dep_graph.package('A'), VersionConstraint.new('>= 10.0.0')),
  SolutionConstraint.new(dep_graph.package('B'), VersionConstraint.new('>= 50.0.0'))
]

begin
  selector.find_solution(invalid_solution_constraints)
rescue Exceptions::InvalidSolutionConstraints => isc
  puts "non-existent solution constraints: #{isc.non_existent_packages.join(', ')}"
  puts "solution constraints whose constraints match no versions of the package: #{isc.constrained_to_no_versions.join(', ')}"
end
```

yields

```text
non-existent solution constraints: (nosuch >= 0.0.0), (nosuch2 >= 0.0.0)
solution constraints whose constraints match no versions of the package: (A >= 10.0.0), (B >= 50.0.0)
```

The Model
---------
The dep_selector model involves the following constructs:

* DependencyGraph, which is populated with Packages
* Package, which has a name that is unique within a DependencyGraph and contains a set of PackageVersions
* PackageVersion, which has a Version that is unique within its Package and contains a set of Dependencies
* Version, which is any object that implements Comparable and abides the hashing contract
  * The implementation included with the library, DepSelector::Version, implements versions of the form X.Y.Z, where X, Y, and Z are integers and compared numerically instead of lexicographically
* Dependency, which has a Package and a VersionConstraint
* VersionConstraint, which is any object that responds to include?(version) with whether the specified Version matches the VersionConstraint
  * The implementation included with the library, DepSelector::VersionConstraint, implements:
    * `=`: strict equality, e.g., VersionConstraint.new("= 1.0.0") will only match 1.0.0
    * `>`: greater than, e.g., VersionConstraint.new("> 1.3.10") will match 1.3.11, 1.4.0, etc. but not 1.3.9 or 1.3.10
    * `<`: less than, e.g., VersionConstraint.new("< 1.3.10") will match 1.3.9, 1.2.0, etc. but not 1.3.10 or 1.3.11
    * `<=` or `>=`: same as the two above but unioned with equality
    * `~>`: pessimistic version constraint (described at http://docs.rubygems.org/read/chapter/16#page74)
* Selector, which contains a DependencyGraph and exposes a method, find_solution, which takes an array of solution constraints (Package-VersionConstraint pairs) and determines a valid assignment of Packages to Versions


More Examples!
--------------
Suppose that there are three packages, A, B, and C, and that the
notation XY denotes version Y of package X (so A1 means version 1 of
package A) and that "A1 -> B=1" means that A1 depends exactly on B1
and that "A2 -> B>=2" means that A2 depends on B>=2. Consider the
dependency graph represented as:

```text
A has versions: 1, 2
B has versions: 1, 2, 3
C has versions: 1
D has versions: 1
A1 -> B=1
A2 -> B>=2, C=1
B3 -> D=1
```

Given a series of constraints, we can then select exact versions of
packages that satisfy the dependency graph and the constraints.

### Simple
For example: [(A), (B=1)]

We are searching for a solution where we must have some version A
selected and that B must be set to version 1.

The only solution is:
  {A=>1, B=>1}
because the constraint on B trivially constrains A to 1.

### Multiple solutions, including induced dependencies
With the constraints [(A), (C=1)], we could choose any one of:

```text
{ A => 1, B => 1, C => 1 }
{ A => 2, B => 2, C => 1 }
{ A => 2, B => 3, C => 1, D => 1 }
```

Note that B is not explicitly constrained or required to be bound but
is selected anyway--it is an induced dependency of every version of
A. Likewise, D does not show up in the solution constraints, but it is
an induced, transitive dependency of A2 given B3.

In the absence of an objective function (see next section), any one of
these solutions will be returned.


Objective functions
-------------------
Objective functions do not modify what solutions are satisfiable; they
merely rank solutions, which necessarily satisfy the constraints, so
that the solution with the highest value for an objective function is
selected.

TODO: example

What if a solution does not exist?
----------------------------------
When generating a solution, we first try to solve the entire system of
constraints, but it may be the case that there is no assignment of
packages to versions that satisfies all the constraints. In this case,
we fall back to starting at the dependency graph and adding the
solution constraints one at a time until the constraint that makes a
solution impossible is determined and returned along with the most
constrained variable in order to hint at where the user can look to
resolve the incompatibility.

For example, given the example dependency graph, if we tried to solve
for [(A=1), (B=2)], as in solution_constraints_3, it's not until we
add the B=2 constraint that the system becomes unsatisfiable, so we
indicate that the unsatisfiability is introduced at that constraint
and that B is the most constrained variable (this is a simple system
of constraints, but if the most constrained variable were a transitive
dependency of the explicitly-defined solution constraints, it would be
much less obvious to the user where to look without providing the most
constrained variable).


The nitty-gritty
----------------
Choosing satisfying versions of packages with backtracking and
accounting for the addition and removal of induced transitive
dependencies is hard, so we decided to go shopping... for a CSP
solver. We re-formulated the dependency graph and the solution
constraints as a CSP and off-loaded the hard work to Gecode, a fast,
license-friendly solver written in C++.

There are a lot of corner cases, and we're doing a lot of modeling
under the hood with objective functions to identify problematic
packages and to select the latest possible versions, but the basic
modeling is as follows:

### Example

```text
Back to our original example:
  Dependency graph:
    A has versions: 1, 2
    B has versions: 1, 2, 3
    C has versions: 1
    D has versions: 1
    A1 -> B=1
    A2 -> B>=2, C=1
    B3 -> D1
  Solution constraints:
    [(A), (B=1)]

This effectively gets transformed into the following boolean expressions:
  Dependency graph:
    ( (A=1 ^ B=1) V ~(A=1) ) ^
    ( (A=2 ^ B>=2 ^ C=1) V ~(A=2) ) ^
    ( (B=3 ^ D=1) V ~(B=3) )
  Solution constraints:
    ( A=1 V A=2 ) ^
    ( B=1 )
```

License & Authors
-----------------
- Author: Dan Deleo (<dan@getchef.com>)
- Author: Chris Walters (<github.algorist@ckwalters.com>)

```text
Copyright 2014 Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
