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

class VersionProblem : public Space
{
 public:
  static const int UNRESOLVED_VARIABLE;
  static const int MIN_TRUST_LEVEL;  
  static const int MAX_TRUST_LEVEL;

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

  // We may wish to indicate that some packages have suspicious constraints, and when chosing packages to disable we 
  // would disable them first. 
  // Trust level 10 is fully trusted, while 0is completely untrusted.
  // 0 makes it free to disable a package, while 10 is the default full trust.
  void MarkPackageSuspicious(int packageId, int trustLevel);

  // Packages marked by this method are preferentially chosen at
  // latest according to weights
  void MarkPackagePreferredToBeAtLatest(int packageId, int weight);

  void Finalize();
  
  virtual void constrain(const Space & _best_known_solution);

  int GetPackageVersion(int packageId);
  bool GetPackageDisabledState(int packageId);
  int GetAFC(int packageId);
  int GetMax(int packageId);
  int GetMin(int packageId);
  int GetDisabledVariableCount();
  
  // Support for gecode
  virtual Space* copy(bool share);

  // Debug and utility functions
  void Print(std::ostream &out);
  void PrintPackageVar(std::ostream & out, int packageId) ;

  static VersionProblem *Solve(VersionProblem *problem);

 protected:
  int size;
  int cur_package;
  bool CheckPackageId(int id);
  bool finalized;
  //  std::vector<int> test;
  BoolVarArgs version_flags;
  IntVarArray package_versions;
  BoolVarArray disabled_package_variables;
  IntVar total_disabled;
  BoolVarArray preferred_at_latest;
  IntVar total_preferred_at_latest;

  IntVar aggregate_cost;

  int * disabled_package_weights;
  int * preferred_at_latest_weights;

  void AddPackagesPreferredToBeAtLatestObjectiveFunction(const VersionProblem & best_known_solution);
};

class Solver {
 public:
  Solver(VersionProblem *s);
  VersionProblem GetNextSolution();
 private:
  Restart<VersionProblem> solver;
};

#endif dep_selector_to_gecode_h
