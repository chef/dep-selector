#ifndef dep_selector_to_gecode_interface_h
#define dep_selector_to_gecode_interface_h

// Conceptual Api
#ifdef __cplusplus
extern "C" {
#endif __cplusplus

#ifdef __cplusplus
  class VersionProblemOCIH;
#else
  typedef struct VersionProblemOCIH VersionProblemOCIH;
#endif

  VersionProblemOCIH * VersionProblemCreate(int packageCount);
  void VersionProblemDestroy(VersionProblemOCIH * vp);


  int VersionProblemSize(VersionProblemOCIH *p);
  int VersionProblemPackageCount(VersionProblemOCIH *p);

  // Return ID #
  int AddPackage(VersionProblemOCIH *problem, int min, int max, int currentVersion);
  // Add constraint for package pkg @ version, 
  // that dependentPackage is at version [minDependentVersion,maxDependentVersion]
  // Returns false if system becomes insoluble.
  bool AddVersionConstraint(VersionProblemOCIH *problem, int packageId, int version, 
			    int dependentPackageId, int minDependentVersion, int maxDependentVersion);

  int GetPackageVersion(VersionProblemOCIH *problem, int packageId);
  int GetPackageAFC(VersionProblemOCIH *problem, int packageId);
  int GetPackageMax(VersionProblemOCIH *problem, int packageId);
  int GetPackageMin(VersionProblemOCIH *problem, int packageId);

  void VersionProblemDump(VersionProblemOCIH * problem);
  void VersionProblemPrintPackageVar(VersionProblemOCIH * problem, int packageId);

  VersionProblemOCIH * Solve(VersionProblemOCIH * problem);

#ifdef __cplusplus
}
#endif __cplusplus

#endif // dep_selector_to_gecode_interface_h
