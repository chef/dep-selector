#ifndef dep_selector_to_gecode_h
#define dep_selector_to_gecode_h

#include "dep_selector_to_gecode_interface.h"
#include <iostream>	       
#include <vector>

#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

using namespace Gecode;

class Package
{
 public:
 Package(Space & _space, int _minVersion, int _maxVersion, int _currentVersion);
 friend std::ostream & operator<< (std::ostream &os, const Package & obj);
 // Debug and utility functions
 friend class VersionProblem;

 private:
  int currentVersion;
  int minVersion;
  int maxVersion;

  IntVar var;
  int index;
};

class VersionProblem : public Script
{
 public:
  VersionProblem();
  // Clone constructor; check gecode rules for this...
  VersionProblem(bool share, VersionProblem & s);
  virtual ~VersionProblem();

  Package * AddPackage(int minVersion, int maxVersion, int currentVersion);

  bool AddVersionConstraint(Package* pkg, int version, 
			    Package* dependentPackage, int minDependentVersion, int maxDependentVersion);
  bool Solve();
  int GetPackageVersion(Package* pkg);
  
  // Support for gecode
  virtual Space* copy(bool share);

  // Debug and utility functions
  void Print(std::ostream &out);
 private:

  //  std::vector<int> test;
  std::vector<Package *> packages;
};


#endif dep_selector_to_gecode_h
