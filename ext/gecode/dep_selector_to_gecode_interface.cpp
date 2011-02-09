//#include "ruby.h"

#include <iostream>

#include "dep_selector_to_gecode_interface.h"
#include "dep_selector_to_gecode.h"

//
// TODO:
//  Trap all exceptions
//  insure proper memory behaviour

// FFI friendly
VersionProblem * VersionProblemCreate() 
{
  return new VersionProblem();
}

void VersionProblemDestroy(VersionProblem * p)
{
  delete p;
}

void VersionProblemDump(VersionProblem *p)
{
  p->Print(std::cout);
  std::cout.flush();
}

void VersionProblemPrintPackageVar(VersionProblem *p, int packageId) 
{
  p->PrintPackageVar(std::cout, packageId);
  std::cout.flush();
}


// Return ID #
int AddPackage(VersionProblem *problem, int min, int max, int currentVersion) {
  problem->AddPackage(min,max,currentVersion);
}
// Add constraint for package pkg @ version, 
// that dependentPackage is at version [minDependentVersion,maxDependentVersion]
// Returns false if system becomes insoluble.
bool AddVersionConstraint(VersionProblem *problem, int packageId, int version, 
			  int dependentPackageId, int minDependentVersion, int maxDependentVersion) 
{
  problem->AddVersionConstraint(packageId, version, dependentPackageId, minDependentVersion, maxDependentVersion);
}

// Solve system; 
bool Solve(VersionProblem *problem) 
{
  problem->Solve();
}

int GetPackageVersion(VersionProblem *problem, int packageId)
{
  problem->GetPackageVersion(packageId);
}


