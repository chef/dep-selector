//#include "ruby.h"

#include <iostream>

#include "dep_selector_to_gecode_interface.h"
//#include "dep_selector_to_gecode.h"
#include "version_problem_oc_ih.h"

//
// TODO:
//  Trap all exceptions
//  insure proper memory behaviour

// FFI friendly
VersionProblemOCIH * VersionProblemCreate(int packageCount) 
{
  return new VersionProblemOCIH(packageCount);
}

void VersionProblemDestroy(VersionProblemOCIH * p)
{
  delete p;
}

int VersionProblemSize(VersionProblemOCIH *p) 
{
  return p->Size();
}

int VersionProblemPackageCount(VersionProblemOCIH *p) 
{
  return p->PackageCount();
}



void VersionProblemDump(VersionProblemOCIH *p)
{
  p->Print(std::cout);
  std::cout.flush();
}

void VersionProblemPrintPackageVar(VersionProblemOCIH *p, int packageId) 
{
  p->PrintPackageVar(std::cout, packageId);
  std::cout.flush();
}

// Return ID #
int AddPackage(VersionProblemOCIH *problem, int min, int max, int currentVersion) {
  problem->AddPackage(min,max,currentVersion);
}
// Add constraint for package pkg @ version, 
// that dependentPackage is at version [minDependentVersion,maxDependentVersion]
// Returns false if system becomes insoluble.
bool AddVersionConstraint(VersionProblemOCIH *problem, int packageId, int version, 
			  int dependentPackageId, int minDependentVersion, int maxDependentVersion) 
{
  problem->AddVersionConstraint(packageId, version, dependentPackageId, minDependentVersion, maxDependentVersion);
}

int GetPackageVersion(VersionProblemOCIH *problem, int packageId)
{
  problem->GetPackageVersion(packageId);
}

int GetPackageAFC(VersionProblemOCIH *problem, int packageId)
{
  problem->GetAFC(packageId);
}

int GetPackageMax(VersionProblemOCIH *problem, int packageId)
{
  problem->GetMax(packageId);
}

int GetPackageMin(VersionProblemOCIH *problem, int packageId)
{
  problem->GetMin(packageId);
}

VersionProblemOCIH * Solve(VersionProblemOCIH * problem)  {
  return VersionProblemOCIH::Solve(problem);
}
