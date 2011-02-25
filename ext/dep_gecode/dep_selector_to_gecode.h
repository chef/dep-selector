#ifndef version_problem_oc_ih_h
#define version_problem_oc_ih_h

#include "dep_selector_to_gecode_interface.h"
#include <iostream>	       
#include <vector>

#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

using namespace Gecode;

// TODO:
// Allow retrieval of multiple solutions
// Understand how assign versions where necessary, and not assign unnecessary versions.
// Understand how to assign empty versions
//

// Extend:
// Add optimization functions
// Allow non-contiguous ranges in package dependencies. 

class VersionProblem : public MinimizeSpace
{
 public:
  static const int UNRESOLVED_VARIABLE;

  VersionProblem(int packageCount);
  // Clone constructor; check gecode rules for this...
  VersionProblem(bool share, VersionProblem & s);
  virtual ~VersionProblem();

  int Size();
  int PackageCount();

  IntVar & GetPackageVersionVar(int packageId);

  virtual int AddPackage(int minVersion, int maxVersion, int currentVersion);

  virtual bool AddVersionConstraint(int packageId, int version, 
			    int dependentPackageId, int minDependentVersion, int maxDependentVersion);
  void Finalize();
  
  virtual IntVar cost(void) const;

  int GetPackageVersion(int packageId);
  bool GetPackageDisabledState(int packageId);
  int GetAFC(int packageId);
  int GetMax(int packageId);
  int GetMin(int packageId);
  
  // Support for gecode
  virtual Space* copy(bool share);

  // Debug and utility functions
  void Print(std::ostream &out);
  void PrintPackageVar(std::ostream & out, int packageId) ;

  static VersionProblem *Solve(VersionProblem *problem);

 protected:
  int cur_package;
  bool CheckPackageId(int id);
  bool finalized;
  //  std::vector<int> test;
  BoolVarArgs version_flags;
  IntVarArray package_versions;
  BoolVarArray disabled_package_variables;
  IntVar total_disabled;
};

class Solver {
 public:
  Solver(VersionProblem *s);
  VersionProblem GetNextSolution();
 private:
  Restart<VersionProblem> solver;
};

#endif dep_selector_to_gecode_h
