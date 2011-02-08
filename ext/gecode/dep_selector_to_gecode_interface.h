#ifndef dep_selector_to_gecode_interface_h
#define dep_selector_to_gecode_interface_h

// Conceptual Api
#ifdef __cplusplus
extern "C" {
#endif __cplusplus

#ifdef __cplusplus
  class VersionProblem;
  class Package;
#else
  typedef struct VersionProblem VersionProblem;
  typedef struct Package Package;
#endif

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

#ifdef __cplusplus
}
#endif __cplusplus

#endif // dep_selector_to_gecode_interface_h
