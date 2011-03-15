#include <iostream>
#include "ext/dep_gecode/dep_selector_to_gecode_interface.h"

// build: g++ test.cpp -o test ext/gecode/dep_selector_to_gecode_interface.o ext/gecode/dep_selector_to_gecode.o -lgecodesupport -lgecodekernel -lgecodeint -lgecodesearch  

using namespace std;


int problem_nosol() {
 VersionProblem* problem = VersionProblemCreate(10);
  // package A has versions 0, 1v
  int pkg_a = AddPackage(problem, 0, 1, 1);
  // package B has versions 0, 1
  int pkg_b = AddPackage(problem, 0, 1, 1);
  // package C has versions 0, 1
  int pkg_c = AddPackage(problem, 0, 1, 0);

  // A0 depends on B1
  AddVersionConstraint(problem, pkg_a, 0, pkg_b, 1, 1);

  // A1 depends on B0, C0
  AddVersionConstraint(problem, pkg_a, 0, pkg_b, 0, 0);
  AddVersionConstraint(problem, pkg_a, 0, pkg_c, 0, 0);

  // B1 depends on C10, which doesn't even exist...
  AddVersionConstraint(problem, pkg_b, 1, pkg_c, 10, 10);

  // metapackage is a "ghost" package whose dependencies are the
  // solution constraints; thereby forcing packages to be
  // appropriately constrained
  int metapkg = AddPackage(problem, 0, 0, 0);

  cout << "before adding solution constraints" << endl;
  VersionProblemPrintPackageVar(problem, pkg_a);
  cout << endl;
  VersionProblemPrintPackageVar(problem, pkg_b);
  cout << endl;
  VersionProblemPrintPackageVar(problem, pkg_c);
  cout << endl;
  VersionProblemPrintPackageVar(problem, metapkg);
  cout << endl;

  // solution constraints: [A,(B=0)], which is satisfiable as A=1, B=0
  // AddVersionConstraint(problem, metapkg, 0, pkg_a, 0, 1);
  //AddVersionConstraint(problem, metapkg, 0, pkg_b, 0, 0);
  // solution constraints: [(A=0),(B=0)], which is not satisfiable
  AddVersionConstraint(problem, metapkg, 0, pkg_a, 0, 0);
  AddVersionConstraint(problem, metapkg, 0, pkg_b, 0, 0);

  cout << "after adding solution constraints" << endl;
  VersionProblemPrintPackageVar(problem, pkg_a);
  cout << endl;
  VersionProblemPrintPackageVar(problem, pkg_b);
  cout << endl;
  VersionProblemPrintPackageVar(problem, pkg_c);
  cout << endl;
  VersionProblemPrintPackageVar(problem, metapkg);
  cout << endl;

  VersionProblem *solution = Solve(problem);
  if (solution != NULL) {
    // solve and interrogate problem
    cout << "after running solve" << endl;
    VersionProblemDump(solution);
    VersionProblemDestroy(solution);
  } else {
    cout << "No solution" << endl;
  }
  VersionProblemDestroy(problem);

}


int problem_sol() {
  VersionProblem* problem = VersionProblemCreate(10);
  // package A has versions 0, 1v
  int pkg_a = AddPackage(problem, 0, 1, 1);
  // package B has versions 0, 1
  int pkg_b = AddPackage(problem, 0, 1, 1);
  // package C has versions 0
  int pkg_c = AddPackage(problem, 0, 0, 0);

  // A0 depends on B1
  AddVersionConstraint(problem, pkg_a, 0, pkg_b, 1, 1);

  // A1 depends on B0, C0
  AddVersionConstraint(problem, pkg_a, 0, pkg_b, 0, 0);
  AddVersionConstraint(problem, pkg_a, 0, pkg_c, 0, 0);

  // metapackage is a "ghost" package whose dependencies are the
  // solution constraints; thereby forcing packages to be
  // appropriately constrained
  int metapkg = AddPackage(problem, 0, 0, 0);

  cout << "before adding solution constraints" << endl;
  VersionProblemPrintPackageVar(problem, pkg_a);
  cout << endl;
  VersionProblemPrintPackageVar(problem, pkg_b);
  cout << endl;
  VersionProblemPrintPackageVar(problem, pkg_c);
  cout << endl;
  VersionProblemPrintPackageVar(problem, metapkg);
  cout << endl;

  // solution constraints: [A,(B=0)], which is satisfiable as A=1, B=0
  AddVersionConstraint(problem, metapkg, 0, pkg_a, 0, 1);
  AddVersionConstraint(problem, metapkg, 0, pkg_b, 0, 0);
  // solution constraints: [(A=0),(B=0)], which is not satisfiable
  //AddVersionConstraint(problem, metapkg, 0, pkg_a, 0, 0);
  //AddVersionConstraint(problem, metapkg, 0, pkg_b, 0, 0);

  cout << "after adding solution constraints" << endl;
  VersionProblemPrintPackageVar(problem, pkg_a);
  cout << endl;
  VersionProblemPrintPackageVar(problem, pkg_b);
  cout << endl;
  VersionProblemPrintPackageVar(problem, pkg_c);
  cout << endl;
  VersionProblemPrintPackageVar(problem, metapkg);
  cout << endl;

  VersionProblem *solution = Solve(problem);
  if (solution != NULL) {
    // solve and interrogate problem
    cout << "after running solve" << endl;
    VersionProblemPrintPackageVar(solution, pkg_a);
    cout << endl;
    VersionProblemPrintPackageVar(solution, pkg_b);
    cout << endl;
    VersionProblemPrintPackageVar(solution, pkg_c);
    cout << endl;
    VersionProblemPrintPackageVar(solution, metapkg);
    cout << endl;
    VersionProblemDestroy(solution);
  } else {
    cout << "No solution" << endl;
  }
  VersionProblemDestroy(problem);
}

int main() {
  problem_nosol();
  problem_sol();
}
