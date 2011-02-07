require 'rubygems'
require 'pp'
require 'dep_selector'

# This example corresponds to the following dependency graph:
#   A has versions: 1, 2
#   B has versions: 1, 2, 3
#   C has versions: 1
#   D has versions: 1
#   A1 -> B=1         (v1 of package A depends on v1 of package B)
#   A2 -> B>=2, C=1   (v2 of package A depends on B at v2 or greater and v1 of C)
#   B3 -> D=1         (v3 of package B depends on v1 of package D)

include DepSelector

# create dependency graph
dep_graph = DependencyGraph.new

# package A has versions 1 and 2
a = dep_graph.package('A')
a1 = a.add_version(Version.new('1.0.0'))
a2 = a.add_version(Version.new('2.0.0'))

# package B has versions 1, 2, and 3
b = dep_graph.package('B')
b1 = b.add_version(Version.new('1.0.0'))
b2 = b.add_version(Version.new('2.0.0'))
b3 = b.add_version(Version.new('3.0.0'))

# package C only has version 1
c = dep_graph.package('C')
c1 = c.add_version(Version.new('1.0.0'))

# package D only has version 1
d = dep_graph.package('D')
d1 = d.add_version(Version.new('1.0.0'))

# package A version 1 has a dependency on package B at exactly 1.0.0
# Note: Though we reference the variable b in the Dependency, packages
# do not have to be created before being referenced.
# DependencyGraph#package looks up the package based on the name or
# auto-vivifies it if it doesn't yet exist, so referring to the
# variable b or calling dep_graph.package('B') before or after b is
# assigned are all equivalent.
a1.dependencies << Dependency.new(b, VersionConstraint.new('= 1.0.0'))

# package A version 2 has dependencies on package B >= 2.0.0 and C at exactly 1.0.0
a2.dependencies << Dependency.new(b, VersionConstraint.new('>= 2.0.0'))
a2.dependencies << Dependency.new(c, VersionConstraint.new('= 1.0.0'))

# package B version 3 has a dependency on package D at exactly 1.0.0
b3.dependencies << Dependency.new(d, VersionConstraint.new('= 1.0.0'))

# create a Selector from the dependency graph
selector = Selector.new(dep_graph)

# define the solution constraints and find a solution

# simple solution
solution_constraints_1 = [
                          SolutionConstraint.new(dep_graph.package('A')),
                          SolutionConstraint.new(dep_graph.package('B'), VersionConstraint.new('= 1.0.0'))
                         ]
pp selector.find_solution(solution_constraints_1)

# more complex solution, which uses a range constraint (>=) and
# demonstrates the assignment of induced transitive dependencies
solution_constraints_2 = [
                          SolutionConstraint.new(dep_graph.package('A')),
                          SolutionConstraint.new(dep_graph.package('B'), VersionConstraint.new('>= 2.1.0'))
                         ]
pp selector.find_solution(solution_constraints_2)

# demonstrates an unsatisfiable set of constraints
solution_constraints_3 = [
                          SolutionConstraint.new(dep_graph.package('A'), VersionConstraint.new('= 1.0.0')),
                          SolutionConstraint.new(dep_graph.package('B'), VersionConstraint.new('= 2.0.0'))
                         ]
pp selector.find_solution(solution_constraints_3)
