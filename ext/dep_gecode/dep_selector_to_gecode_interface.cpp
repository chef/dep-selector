//#include "ruby.h"

#include <iostream>

#include "dep_selector_to_gecode_interface.h"
#include "dep_selector_to_gecode.h"
//#include "version_problem_oc_ih.h"

//
// TODO:
//  Trap all exceptions
//  insure proper memory behaviour

// FFI friendly
VersionProblem * VersionProblemCreate(int packageCount) 
{
  return new VersionProblem(packageCount);
}

void VersionProblemDestroy(VersionProblem * p)
{
  delete p;
}

int VersionProblemSize(VersionProblem *p) 
{
  return p->Size();
}

int VersionProblemPackageCount(VersionProblem *p) 
{
  return p->PackageCount();
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

void MarkPackageSuspicious(VersionProblem *problem, int packageId, int trustLevel) 
{
  problem->MarkPackageSuspicious(packageId, trustLevel);
}

void MarkPackagePreferredToBeAtLatest(VersionProblem *problem, int packageId, int weight)
{
  problem->MarkPackagePreferredToBeAtLatest(packageId, weight);
}

int GetPackageVersion(VersionProblem *problem, int packageId)
{
  problem->GetPackageVersion(packageId);
}

bool GetPackageDisabledState(VersionProblem *problem, int packageId)
{
  problem->GetPackageDisabledState(packageId);
}

int GetPackageAFC(VersionProblem *problem, int packageId)
{
  problem->GetAFC(packageId);
}

int GetPackageMax(VersionProblem *problem, int packageId)
{
  problem->GetMax(packageId);
}

int GetPackageMin(VersionProblem *problem, int packageId)
{
  problem->GetMin(packageId);
}

int GetDisabledVariableCount(VersionProblem *problem)
{
  problem->GetDisabledVariableCount();
}


VersionProblem * Solve(VersionProblem * problem)  {
  return VersionProblem::Solve(problem);
}
