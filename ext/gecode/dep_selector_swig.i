%module "dep_gecode"
%{
#include "dep_selector_to_gecode_interface.h"
%}

class VersionProblem;
class Package;

VersionProblem * VersionProblemCreate();
void VersionProblemDestroy();
// Return ID #
  Package * AddPackage(VersionProblem *problem, int min, int max, int currentVersion);
// Add constraint for package pkg @ version, 
// that dependentPackage is at version [minDependentVersion,maxDependentVersion]
  // Returns false if system becomes insoluble.
bool AddVersionConstraint(VersionProblem *problem, Package *pkg, int version, 
			  Package *pkg, int minDependentVersion, int maxDependentVersion);
// Solve system; 
  bool Solve(VersionProblem *problem);
int GetPackageVersion(VersionProblem *problem, Package *pkg);

void VersionProblemDump(VersionProblem * problem);
