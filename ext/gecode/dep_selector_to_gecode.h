#ifndef dep_selector_to_gecode_h
#define dep_selector_to_gecode_h

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

class VersionProblem : public Script
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

  int AddPackage(int minVersion, int maxVersion, int currentVersion);

  bool AddVersionConstraint(int packageId, int version, 
			    int dependentPackageId, int minDependentVersion, int maxDependentVersion);
  void Finalize();
  


  int GetPackageVersion(int packageId);
  int GetAFC(int packageId);
  int GetMax(int packageId);
  int GetMin(int packageId);
  
  // Support for gecode
  virtual Space* copy(bool share);

  // Debug and utility functions
  void Print(std::ostream &out);
  void PrintPackageVar(std::ostream & out, int packageId) ;


  static VersionProblem *Solve(VersionProblem *problem);

 private:
  int cur_package;
  bool CheckPackageId(int id);
  bool finalized;
  //  std::vector<int> test;
  BoolVarArgs version_flags;
  IntVarArray package_versions;
};

class Solver {
 public:
  Solver(VersionProblem *s);
  VersionProblem GetNextSolution();
 private:
  DFS<VersionProblem> solver;
}


#endif dep_selector_to_gecode_h
