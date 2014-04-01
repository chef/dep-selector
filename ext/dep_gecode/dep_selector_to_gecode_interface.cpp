//
// Author:: Christopher Walters (<cw@opscode.com>)
// Author:: Mark Anderson (<mark@opscode.com>)
// Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
// License:: Apache License, Version 2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include <iostream>

#include "dep_selector_to_gecode_interface.h"
#include "dep_selector_to_gecode.h"
//#include "version_problem_oc_ih.h"

//
// TODO:
//  Trap all exceptions
//  insure proper memory behaviour

// FFI friendly
VersionProblem * VersionProblemCreate(int packageCount, bool dump_stats,
                                      bool debug, const char * logId) 
{
  return new VersionProblem(packageCount, dump_stats, debug, logId);
}

void VersionProblemDestroy(VersionProblem * p)
{
  delete p;
}

int VersionProblemSize(VersionProblem *p) 
{
  return p->Size();
}

int VersionProblemPackageCount(VersionProblem *p) 
{
  return p->PackageCount();
}



void VersionProblemDump(VersionProblem *p)
{
  p->Print(std::cout);
  std::cout.flush();
}

void VersionProblemPrintPackageVar(VersionProblem *p, int packageId) 
{
  p->PrintPackageVar(std::cout, packageId);
  std::cout.flush();
}

// Return ID #
int AddPackage(VersionProblem *problem, int min, int max, int currentVersion) {
  return problem->AddPackage(min,max,currentVersion);
}
// Add constraint for package pkg @ version, 
// that dependentPackage is at version [minDependentVersion,maxDependentVersion]
// Returns false if system becomes insoluble.
void AddVersionConstraint(VersionProblem *problem, int packageId, int version,
			  int dependentPackageId, int minDependentVersion, int maxDependentVersion) 
{
  return problem->AddVersionConstraint(packageId, version, dependentPackageId, minDependentVersion, maxDependentVersion);
}

void MarkPackageSuspicious(VersionProblem *problem, int packageId) 
{
  return problem->MarkPackageSuspicious(packageId);
}

void MarkPackagePreferredToBeAtLatest(VersionProblem *problem, int packageId, int weight)
{
  return problem->MarkPackagePreferredToBeAtLatest(packageId, weight);
}

void MarkPackageRequired(VersionProblem *problem, int packageId)
{
  return problem->MarkPackageRequired(packageId);
}

int GetPackageVersion(VersionProblem *problem, int packageId)
{
  return problem->GetPackageVersion(packageId);
}

bool GetPackageDisabledState(VersionProblem *problem, int packageId)
{
  return problem->GetPackageDisabledState(packageId);
}

int GetPackageMax(VersionProblem *problem, int packageId)
{
  return problem->GetMax(packageId);
}

int GetPackageMin(VersionProblem *problem, int packageId)
{
  return problem->GetMin(packageId);
}

int GetDisabledVariableCount(VersionProblem *problem)
{
  return problem->GetDisabledVariableCount();
}


VersionProblem * Solve(VersionProblem * problem)  {
  return VersionProblem::Solve(problem);
}
