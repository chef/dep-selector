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

#ifndef dep_selector_to_gecode_h
#define dep_selector_to_gecode_h

#include "dep_selector_to_gecode_interface.h"
#include <iostream>	       
#include <vector>
#include <set>

#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

using namespace Gecode;

// TODO:
// Allow retrieval of multiple solutions
// Understand how assign versions where necessary, and not assign unnecessary versions.
// Understand how to assign empty versions
//

// Extend:
// Add optimization functions
// Allow non-contiguous ranges in package dependencies. 

// TODO: Add locking 
struct VersionProblemPool 
{
    std::set<VersionProblem *> elems;
    VersionProblemPool();
    ~VersionProblemPool();
    void Add(VersionProblem * vp);
    void Delete(VersionProblem *vp);
    void ShowAll();
    void DeleteAll();
};

#define DEBUG_PREFIX_LENGTH 40

class VersionProblem : public Space
{
public:
  static const int UNRESOLVED_VARIABLE;
  static const int MIN_TRUST_LEVEL;  
  static const int MAX_TRUST_LEVEL;
  static const int MAX_PREFERRED_WEIGHT;

  static int instance_counter;

    VersionProblem(int packageCount, bool dumpStats = true, 
                   bool debug = false, 
                   const char * logId = 0);
  // Clone constructor; check gecode rules for this...
  VersionProblem(bool share, VersionProblem & s);
  virtual ~VersionProblem();

  int Size();
  int PackageCount();

  IntVar * GetPackageVersionVar(int packageId);

  virtual int AddPackage(int minVersion, int maxVersion, int currentVersion);

  virtual void AddVersionConstraint(int packageId, int version,
			    int dependentPackageId, int minDependentVersion, int maxDependentVersion);

  // We may wish to indicate that some packages have suspicious constraints, and when chosing packages to disable we 
  // would disable them first. 
  void MarkPackageSuspicious(int packageId);

  void MarkPackageRequired(int packageId); 

  // Packages marked by this method are preferentially chosen at
  // latest according to weights
  void MarkPackagePreferredToBeAtLatest(int packageId, int weight);

  void Finalize();
  
  virtual void constrain(const Space & _best_known_solution);

  int GetPackageVersion(int packageId);
  bool GetPackageDisabledState(int packageId);
  int GetMax(int packageId);
  int GetMin(int packageId);
  int GetDisabledVariableCount();
  
  // Support for gecode
  virtual Space* copy(bool share);

  // Debug and utility functions
  void Print(std::ostream &out);
  void PrintPackageVar(std::ostream & out, int packageId) ;
  const char * DebugPrefix() const { return debugPrefix; }

  static VersionProblem *InnerSolve(VersionProblem * problem, int & itercount);
  static VersionProblem *Solve(VersionProblem *problem);

 protected:
  int instance_id;
  int size;
  int version_constraint_count;
  int cur_package;
  bool dump_stats;
  bool debugLogging;
  char debugPrefix[DEBUG_PREFIX_LENGTH];
  char outputBuffer[1024];
  bool finalized;

  BoolVarArgs version_flags;
  IntVarArray package_versions;
  BoolVarArray disabled_package_variables;
  IntVar total_disabled;

  IntVar total_required_disabled;
  IntVar total_induced_disabled;
  IntVar total_suspicious_disabled;

  BoolVarArray at_latest;
  IntVar total_preferred_at_latest;
  IntVar total_not_preferred_at_latest;

  int * preferred_at_latest_weights;
  int * is_required;
  int * is_suspicious;

  VersionProblemPool *pool;

  bool CheckPackageId(int id);
  void AddPackagesPreferredToBeAtLatestObjectiveFunction(const VersionProblem & best_known_solution);
  void ConstrainVectorLessThanBest(IntVarArgs & current, IntVarArgs & best);
  void BuildCostVector(IntVarArgs & costVector) const;
 
  friend class VersionProblemPool;
};

template<class T> void PrintVarAligned(const char * message, T & var);
template<class S, class T> void PrintVarAligned(const char * message, S & var1, T & var2);

class Solver {
 public:
  Solver(VersionProblem *s);
  VersionProblem GetNextSolution();
 private:
  Restart<VersionProblem> solver;
};

#endif // dep_selector_to_gecode_h
