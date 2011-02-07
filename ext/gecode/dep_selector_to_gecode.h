#ifndef dep_selector_to_gecode_h
#define dep_selector_to_gecode_h

#include "dep_selector_to_gecode_interface.h"
#include <vector>

class VersionProblem : public Script {
 public:
  VersionProblem();
  VersionProblem * Clone();
  bool AddVersionConstraint(Package* pkg, int version, 
			    Package* dependentPackage, int minDependentVersion, int maxDependentVersion);
  bool Solve();
  int GetPackageVersion(Package* pkg);

  Package * AddPackage(int minVersion, int maxVersion, int currentVersion);
  
  vector<Package *> packages;
};

class Package {
 public:
  int currentVersion;
  int minVersion;
  int maxVersion;

  IntVar var;
}

#endif dep_selector_to_gecode_h
