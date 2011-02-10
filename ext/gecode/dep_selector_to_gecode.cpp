#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>
#include <gecode/gist.hh>
#include <gecode/search.hh>

#include "dep_selector_to_gecode.h"

#include <iostream>
#include <vector>
//
// T
//

using namespace Gecode;

//
// Version Problem
//
const int VersionProblem::UNRESOLVED_VARIABLE = -1;


VersionProblem::VersionProblem() 
  : finalized(false)
{
}

// Clone constructor; check gecode rules for this...
VersionProblem::VersionProblem(bool share, VersionProblem & s) 
  : Script(share, s), finalized(s.finalized)
{
  package_versions.update(*this, share, s.package_versions);
}

// Support for gecode
Space* VersionProblem::copy(bool share) 
{
  return new VersionProblem(share,*this);
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
  BoolVar version_match(*this, 0, 1);
  BoolVar depend_match(*this, 0, 1);
  //version_flags << version_match;
  // Constrain pred to reify package @ version
  rel(*this, package_version_accumulator[packageId], IRT_EQ, version, version_match);
  // Add the predicated version constraints imposed on dependent package
  dom(*this, package_version_accumulator[dependentPackageId], minDependentVersion, maxDependentVersion, depend_match);
  rel(*this, version_match, BOT_IMP, depend_match, 1);  
}

void VersionProblem::Finalize() 
{
  finalized = true;
  package_versions = IntVarArray(*this, package_version_accumulator);
  branch(*this, package_versions, INT_VAR_SIZE_MIN, INT_VAL_MAX);
}

IntVar & VersionProblem::GetPackageVersionVar(int packageId)
{
  if (finalized) {
    return package_versions[packageId];
  } else {
    return package_version_accumulator[packageId];
  }
}

int VersionProblem::GetPackageVersion(int packageId) 
{
  IntVar & var = GetPackageVersionVar(packageId);
  if (1 == var.size()) return var.val();
  return UNRESOLVED_VARIABLE;
}
int VersionProblem::GetAFC(int packageId)
{
  return GetPackageVersionVar(packageId).afc();
}  

int VersionProblem::GetMax(int packageId)
{
  return GetPackageVersionVar(packageId).max();
}
int VersionProblem::GetMin(int packageId)
{
  return GetPackageVersionVar(packageId).min();
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
  IntVar & var = GetPackageVersionVar(packageId);
  out << "PackageId: " << packageId <<  " Sltn: " << var.min() << " - " << var.max() << " afc: " << var.afc();
}

bool VersionProblem::CheckPackageId(int id) 
{
  return (id < package_version_accumulator.size()) || (id < package_versions.size());
}

VersionProblem * VersionProblem::Solve(VersionProblem * problem) 
{
  problem->Finalize();
  problem->status();
  problem->Print(std::cout);
  DFS<VersionProblem> solver(problem);
  
  // std::cout << solver.statistics();

  if (VersionProblem * solution = solver.next())
    {
      return solution;
    }
  return 0;
}
