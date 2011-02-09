#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>
#include "dep_selector_to_gecode.h"

#include <iostream>
#include <vector>
//
// T
//

using namespace Gecode;

Package::Package(Space & _space, int _minVersion, int _maxVersion, int _currentVersion) 
  : minVersion(_minVersion), maxVersion(_maxVersion), currentVersion(_currentVersion), 
    var(_space, _minVersion, _maxVersion),
    index(0)
{
    
}

std::ostream & operator <<(std::ostream &os, const Package & obj) 
{
  os << "Id: " << index <<  " Initial range: " <<  obj.minVersion << " - " << obj.maxVersion << " (" << obj.currentVersion << ") ";
  os << " Sltn: " << obj.var.min() << " - " << obj.var.max() << " afc: " << obj.var.afc();
  
  return os;
}

//
// Version Problem
//
const int VersionProblem::UNRESOLVED_VARIABLE = -1;


VersionProblem::VersionProblem() 
{


}


// Clone constructor; check gecode rules for this...
VersionProblem::VersionProblem(bool share, VersionProblem & s) 
  : Script(share, s)
{
  package_versions.update(*this, share, s.package_versions);
}

VersionProblem::~VersionProblem() {
}


int
VersionProblem::AddPackage(int minVersion, int maxVersion, int currentVersion) 
{
  int index = package_version_accumulator.size();
  IntVar version(*this, minVersion, maxVersion);
  package_version_accumulator << version;
  return index;
}

bool 
VersionProblem::AddVersionConstraint(int packageId, int version, 
				     int dependentPackageId, int minDependentVersion, int maxDependentVersion) 

{
  BoolVar pred(*this, 0, 1);
  version_flags << pred;
  // Constrain pred to reify package @ version
  rel(*this, package_version_accumulator[packageId], IRT_EQ, version, pred);
  // Add the predicated version constraints imposed on dependent package
  dom(*this, package_version_accumulator[dependentPackageId], minDependentVersion, maxDependentVersion, pred);
}

bool VersionProblem::Solve() 
{
  package_versions = IntVarArray(*this, package_version_accumulator);
  branch(*this, package_versions, INT_VAR_SIZE_MIN, INT_VAL_MAX);
}

int VersionProblem::GetPackageVersion(int packageId) 
{
   IntVar & var = package_versions[packageId];
   if (1 == var.size()) return var.val();
   return UNRESOLVED_VARIABLE;
}
  
// Support for gecode
Space* VersionProblem::copy(bool share) 
{
  return new VersionProblem(share,*this);
}

// Utility
void VersionProblem::Print(std::ostream & out) 
{
  out << "Version problem dump: " << package_versions.size() << " elements" << std::endl;
  for (int i = 0; i < package_versions.size(); i++) {
    out << "\t";
    PrintPackageVar(out, i);
    out << std::endl;
  }
}

// TODO: Validate package ids !

void VersionProblem::PrintPackageVar(std::ostream & out, int packageId) 
{
  // Hack Alert: we could have the package variable in one of two places, but we don't clearly distinguish where.
  IntVar & var = package_version_accumulator[packageId];
  if (package_versions.size() > 0) { 
    var = package_versions[packageId];
  }
  out << "PackageId: " << packageId <<  " Sltn: " << var.min() << " - " << var.max() << " afc: " << var.afc();
}

bool VersionProblem::CheckPackageId(int id) 
{
  return (id < package_version_accumulator.size()) || (id < package_versions.size());
}
