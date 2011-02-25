#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>
#include <gecode/gist.hh>
#include <gecode/search.hh>

#include "version_problem_oc_ih.h"

#include <limits>
#include <iostream>
#include <vector>

#undef DEBUG

const int VersionProblemOCIH::UNRESOLVED_VARIABLE = INT_MIN;

using namespace Gecode;

VersionProblemOCIH::VersionProblemOCIH(int packageCount)
  : finalized(false), cur_package(0), package_versions(*this, packageCount), 
    disabled_package_variables(*this, packageCount, 0, 1), total_disabled(*this, 0, packageCount)
{
}

VersionProblemOCIH::VersionProblemOCIH(bool share, VersionProblemOCIH & s) 
  : MinimizeSpace(share, s),
    finalized(s.finalized), cur_package(s.cur_package),
    disabled_package_variables(s.disabled_package_variables), total_disabled(s.total_disabled)
{
  package_versions.update(*this, share, s.package_versions);
  disabled_package_variables.update(*this, share, s.disabled_package_variables);
  total_disabled.update(*this, share, s.total_disabled);
}

// Support for gecode
Space* VersionProblemOCIH::copy(bool share) 
{
  return new VersionProblemOCIH(share,*this);
}

VersionProblemOCIH::~VersionProblemOCIH() 
{

}

int VersionProblemOCIH::Size() 
{
  return package_versions.size();
}

int VersionProblemOCIH::PackageCount() 
{
  return cur_package;
}

int
VersionProblemOCIH::AddPackage(int minVersion, int maxVersion, int currentVersion) 
{
  if (cur_package == package_versions.size()) {
    return -1;
  }

#ifdef DEBUG
  std::cout << cur_package << '/' << package_versions.size() << ":" << minVersion << ", " << maxVersion << ", " << currentVersion << std::endl;
  std::cout.flush();    
#endif // DEBUG
  int index = cur_package;
  cur_package++;
  //  IntVar version(*this, minVersion, maxVersion);
  package_versions[index] = IntVar(*this, minVersion, maxVersion);
  return index;
}

bool 
VersionProblemOCIH::AddVersionConstraint(int packageId, int version, 
							int dependentPackageId, int minDependentVersion, int maxDependentVersion) 
{
  BoolVar version_match(*this, 0, 1);
  BoolVar depend_match(*this, 0, 1);
  BoolVar predicated_depend_match(*this, 0, 1);

  //version_flags << version_match;
  // Constrain pred to reify package @ version
  rel(*this, package_versions[packageId], IRT_EQ, version, version_match);
  // Add the predicated version constraints imposed on dependent package
  dom(*this, package_versions[dependentPackageId], minDependentVersion, maxDependentVersion, depend_match);

  // disabled_package_variables[dependentPackageId] OR depend_match <=> predicated_depend_match
  rel(*this, disabled_package_variables[dependentPackageId], BOT_OR, depend_match, predicated_depend_match);

  rel(*this, version_match, BOT_IMP, predicated_depend_match, 1);  
}


void VersionProblemOCIH::Finalize() 
{
#ifdef DEBUG
  std::cout << "Finalization Started" << std::endl;
  std::cout.flush();
#endif // DEBUG
  finalized = true;
  // Setup constraint for cost
  linear(*this, disabled_package_variables, IRT_EQ, total_disabled);

  // Assign a dummy variable to elements greater than actually used.
  for (int i = cur_package; i < package_versions.size(); i++) {
    package_versions[i] = IntVar(*this, -1, -1);
    disabled_package_variables[i] = BoolVar(*this, 1, 1);
  }
#ifdef DEBUG
  std::cout << "Branch Started" << std::endl;
  std::cout.flush();
#endif // DEBUG
  branch(*this, disabled_package_variables, INT_VAR_SIZE_MIN, INT_VAL_MIN);
  branch(*this, package_versions, INT_VAR_SIZE_MIN, INT_VAL_MAX);
#ifdef DEBUG
  std::cout << "Finalization Done" << std::endl;
  std::cout.flush();
#endif // DEBUG
}

IntVar VersionProblemOCIH::cost(void) const {
  return total_disabled;
}



IntVar & VersionProblemOCIH::GetPackageVersionVar(int packageId)
{
  if (packageId < cur_package) {
    return package_versions[packageId];
  } else {
#ifdef DEBUG
    std::cout << "Bad package Id " << packageId << " >= " << cur_package << std::endl;
    std::cout.flush();
#endif //DEBUG
    //    return 0;
  }
}

int VersionProblemOCIH::GetPackageVersion(int packageId) 
{
  IntVar & var = GetPackageVersionVar(packageId);
  if (1 == var.size()) return var.val();
  return UNRESOLVED_VARIABLE;
}
bool VersionProblemOCIH::GetPackageDisabledState(int packageId) 
{
  return disabled_package_variables[packageId].val();
}

int VersionProblemOCIH::GetAFC(int packageId)
{
  return GetPackageVersionVar(packageId).afc();
}  

int VersionProblemOCIH::GetMax(int packageId)
{
  return GetPackageVersionVar(packageId).max();
}
int VersionProblemOCIH::GetMin(int packageId)
{
  return GetPackageVersionVar(packageId).min();
}

// Utility
void VersionProblemOCIH::Print(std::ostream & out) 
{
  out << "Version problem dump: " << cur_package << "/" << package_versions.size() << " packages used/allocated" << std::endl;
  for (int i = 0; i < cur_package; i++) {
    out << "\t";
    PrintPackageVar(out, i);
    out << std::endl;
  }
  out.flush();
}

// TODO: Validate package ids !

void VersionProblemOCIH::PrintPackageVar(std::ostream & out, int packageId) 
{
  // Hack Alert: we could have the package variable in one of two places, but we don't clearly distinguish where.
  IntVar & var = GetPackageVersionVar(packageId);
  out << "PackageId: " << packageId <<  " Sltn: " << var.min() << " - " << var.max() << " afc: " << var.afc();
  out << " disabled: " << disabled_package_variables[packageId].min() << " - " << disabled_package_variables[packageId].max();
}

bool VersionProblemOCIH::CheckPackageId(int id) 
{
  return (id < package_versions.size());
}

VersionProblemOCIH * VersionProblemOCIH::Solve(VersionProblemOCIH * problem) 
{
  problem->Finalize();
  problem->status();
#ifdef DEBUG
  problem->Print(std::cout);
#endif //DEBUG
  Restart<VersionProblemOCIH> solver(problem);
  
  // std::cout << solver.statistics();

  if (VersionProblemOCIH * solution = solver.next())
    {
      return solution;
    }
  return 0;
}


//
// 
//



//
// Version Problem
//
//
// 
//
