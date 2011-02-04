#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

using namespace Gecode;

// Conceptual Api
extern "C" {
  struct VersionProblem;
  struct Package;
  VersionProblem * NewVersionProblem;
  // Return ID #
  Package * AddPackage(VersionProblem *problem, int min, int max, int currentVersion);
  // Add constraint for package pkg @ version, that dependentPackage is at version GE dependentVersion
  // Returns false if system becomes insoluble.
  bool AddVersionConstraintGE(VersionProblem *problem, Package *pkg, int version, Package *pkg, int dependentVersion);
  bool AddVersionConstraintEQ(VersionProblem *problem, Package *pkg, int version, Package *pkg, int dependentVersion);
  bool AddVersionConstraintLE(VersionProblem *problem, Package *pkg, int version, Package *pkg, int dependentVersion);

  bool Solve(VersionProblem *problem);

  int GetPackageVersion(VersionProblem *problem, Package *pkg);
}
