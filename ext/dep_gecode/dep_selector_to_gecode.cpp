#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>
#include <gecode/gist.hh>
#include <gecode/search.hh>

#include "dep_selector_to_gecode.h"

#include <limits>
#include <iostream>
#include <vector>

#define DEBUG

using namespace Gecode;
const int VersionProblem::UNRESOLVED_VARIABLE = INT_MIN;
const int VersionProblem::MIN_TRUST_LEVEL = 0;
const int VersionProblem::MAX_TRUST_LEVEL = 10;

VersionProblem::VersionProblem(int packageCount)
  : size(packageCount), finalized(false), cur_package(0), package_versions(*this, packageCount), 
    disabled_package_variables(*this, packageCount, 0, 1), total_disabled(*this, 0, packageCount*MAX_TRUST_LEVEL),
    disabled_package_weights(new int[packageCount]), preferred_at_latest(*this, packageCount, 0, 1),
    total_preferred_at_latest(*this, 0, packageCount), preferred_at_latest_weights(new int[packageCount])
{
  for (int i = 0; i < packageCount; i++)
  {
    disabled_package_weights[i] = MAX_TRUST_LEVEL;
    preferred_at_latest_weights[i] = 0;
  }
}

VersionProblem::VersionProblem(bool share, VersionProblem & s) 
  : Space(share, s), size(s.size),
    finalized(s.finalized), cur_package(s.cur_package),
    disabled_package_variables(s.disabled_package_variables), total_disabled(s.total_disabled),
    disabled_package_weights(NULL), preferred_at_latest(s.preferred_at_latest),
    total_preferred_at_latest(s.total_preferred_at_latest), preferred_at_latest_weights(NULL)
{
  package_versions.update(*this, share, s.package_versions);
  disabled_package_variables.update(*this, share, s.disabled_package_variables);
  total_disabled.update(*this, share, s.total_disabled);
  preferred_at_latest.update(*this, share, s.preferred_at_latest);
  total_preferred_at_latest.update(*this, share, s.total_preferred_at_latest);
}

// Support for gecode
Space* VersionProblem::copy(bool share)
{
  return new VersionProblem(share,*this);
}

VersionProblem::~VersionProblem() 
{
  delete[] disabled_package_weights;
  delete[] preferred_at_latest_weights;
}

int VersionProblem::Size() 
{
  return size;
}

int VersionProblem::PackageCount() 
{
  return cur_package;
}

int
VersionProblem::AddPackage(int minVersion, int maxVersion, int currentVersion) 
{
  if (cur_package == size) {
    return -1;
  }

#ifdef DEBUG
  std::cout << "Adding package id " << cur_package << '/' << size << ": min = " << minVersion << ", max = " << maxVersion << ", current verison " << currentVersion << std::endl;
  std::cout.flush();    
#endif // DEBUG
  int index = cur_package;
  cur_package++;
  //  IntVar version(*this, minVersion, maxVersion);
  package_versions[index] = IntVar(*this, minVersion, maxVersion);

  // register the binding of package to version that corresponds to the package's latest
  rel(*this, package_versions[index], IRT_EQ, maxVersion, preferred_at_latest[index]);

  return index;
}

bool 
VersionProblem::AddVersionConstraint(int packageId, int version, 
				     int dependentPackageId, int minDependentVersion, int maxDependentVersion) 
{
  BoolVar version_match(*this, 0, 1);
  BoolVar depend_match(*this, 0, 1);
  BoolVar predicated_depend_match(*this, 0, 1);

#ifdef DEBUG
  std::cout << "Add VC for " << packageId << " @ " << version << " depPkg " << dependentPackageId;
  std::cout << " [ " << minDependentVersion << ", " << maxDependentVersion << " ]" << std::endl;
  std::cout.flush();
#endif // DEBUG


  //version_flags << version_match;
  // Constrain pred to reify package @ version
  rel(*this, package_versions[packageId], IRT_EQ, version, version_match);
  // Add the predicated version constraints imposed on dependent package

  // package_versions[dependendPackageId] in domain [minDependentVersion,maxDependentVersion] <=> depend_match
  dom(*this, package_versions[dependentPackageId], minDependentVersion, maxDependentVersion, depend_match);

  // disabled_package_variables[dependentPackageId] OR depend_match <=> predicated_depend_match
  // rel(*this, disabled_package_variables[dependentPackageId], BOT_OR, depend_match, version_match);

  rel(*this, disabled_package_variables[dependentPackageId], BOT_OR, depend_match, predicated_depend_match);
  rel(*this, version_match, BOT_IMP, predicated_depend_match, 1);  
}

void
VersionProblem::MarkPackageSuspicious(int packageId, int trustLevel) 
{
  disabled_package_weights[packageId] = std::max(MIN_TRUST_LEVEL, std::min(disabled_package_weights[packageId], trustLevel));
}

void
VersionProblem::MarkPackagePreferredToBeAtLatest(int packageId, int weight)
{
  preferred_at_latest_weights[packageId] = weight;
}

void VersionProblem::Finalize() 
{
#ifdef DEBUG
  std::cout << "Finalization Started" << std::endl;
  std::cout.flush();
#endif // DEBUG
  finalized = true;

  // Setup constraint for cost
  //  linear(*this, disabled_package_weights, disabled_package_variables,  IRT_EQ, total_disabled);
  IntArgs disabled_package_weights_args(size, disabled_package_weights);
  //IntArgs package_weights = IntArgs::create(size, 1, 0);

#ifdef DEBUG
  std::cout << "disabled_package_weights_args: " << disabled_package_weights_args << std::endl;
#endif DEBUG
  linear(*this, disabled_package_weights_args, disabled_package_variables,  IRT_EQ, total_disabled);
  // linear(*this, disabled_package_variables,  IRT_EQ, total_disabled);

  IntArgs preferred_at_latest_weights_args(size, preferred_at_latest_weights);
  linear(*this, preferred_at_latest_weights_args, preferred_at_latest, IRT_EQ, total_preferred_at_latest);

  // Assign a dummy variable to elements greater than actually used.
  for (int i = cur_package; i < size; i++) {
    package_versions[i] = IntVar(*this, -1, -1);
    disabled_package_variables[i] = BoolVar(*this, 1, 1);
  }
#ifdef DEBUG
  std::cout << "preferred_at_latest_weights_args: " << preferred_at_latest_weights_args << std::endl;
  std::cout << "Adding branching" << std::endl;
  std::cout.flush();
#endif // DEBUG
  branch(*this, disabled_package_variables, INT_VAR_SIZE_MIN, INT_VAL_MIN);
  branch(*this, package_versions, INT_VAR_SIZE_MIN, INT_VAL_MAX);
  branch(*this, total_disabled, INT_VAL_MIN);
  branch(*this, preferred_at_latest, INT_VAR_SIZE_MIN, INT_VAL_MAX);
  branch(*this, total_preferred_at_latest, INT_VAL_MAX);
#ifdef DEBUG
  std::cout << "Finalization Done" << std::endl;
  std::cout.flush();
#endif // DEBUG
}

// _best_known_soln is the most recent satisfying assignment of
// variables that Gecode has found. This method examines the solution
// and adds additional constraints that are applied after restarting
// the search, which means that the next time a solution that's found
// must be strictly better than the current best known solution.
//
// Our model requires us to have a series of objective functions where
// each successive objective function is evaluated if and only if all
// higher precedent objective functions are tied.
//
// [TODO: DESCRIBE WHAT THE ACTUAL SERIES OF OBJECTIVE FUNCTIONS IS]
//
// Lower precedent objective functions are modeled as the consequent
// of an implication whose antecedent is the conjunction of all the
// higher precedent objective functions being assigned to their best
// known value; thus, the optimal value of an objection function
// "activates" the next highest objective function. This has the
// effect of isolating the logic of each objective function such that
// it is only applied to the set of equally preferable solutions under
// the higher precedent objective functions. The objective function
// then applies its constraints, the solution space is restarted and
// walks the space until it finds another, more constrained solution.
void VersionProblem::constrain(const Space & _best_known_solution)
{
  const VersionProblem& best_known_solution = static_cast<const VersionProblem &>(_best_known_solution);

  // add first-level objective function minimization (failing packages, weighted)
  // new constraint: total_disabled < best_known_total_disabled_value)
  int best_known_total_disabled_value = best_known_solution.total_disabled.val();
  rel(*this, total_disabled, IRT_LE, best_known_total_disabled_value);

  // add second-level objective function maximization (preferred packages are at latest, weighted)
  AddPackagesPreferredToBeAtLatestObjectiveFunction(best_known_solution);

#ifdef DEBUG
  std::cout << "best_known_total_disabled_value: " << best_known_total_disabled_value << std::endl;
#endif
}

void VersionProblem::AddPackagesPreferredToBeAtLatestObjectiveFunction(const VersionProblem & best_known_solution)
{
  // Make sure we respect total_disabled first by only constraining on
  // latestness of preferred packages if the solution's total_disabled
  // is equivalent to the best known, which is what
  // is_at_best_known_disabled_value represents.

  // is_at_best_known_disabled_value <=> (total_disabled == best_known_total_disabled_value)
  BoolVar is_at_best_known_disabled_value(*this, 0, 1);
  rel(*this, total_disabled, IRT_EQ, best_known_solution.total_disabled.val(), is_at_best_known_disabled_value);

  // is_better_total_preferred_at_latest <=> (total_preferred_at_latest > best_known_total_preferred_at_latest_value)
  int best_known_total_preferred_at_latest_value = best_known_solution.total_preferred_at_latest.val();
  BoolVar is_better_total_preferred_at_latest(*this, 0, 1);
  rel(*this, total_preferred_at_latest, IRT_GR, best_known_total_preferred_at_latest_value, is_better_total_preferred_at_latest);

  // new constraint: is_at_best_known_disabled_value -> is_better_total_preferred_at_latest
  rel(*this, is_at_best_known_disabled_value, BOT_IMP, is_better_total_preferred_at_latest, 1);

#ifdef DEBUG
  std::cout << "best_known_total_preferred_at_latest_value: " << best_known_total_preferred_at_latest_value << std::endl;
#endif
}

IntVar & VersionProblem::GetPackageVersionVar(int packageId)
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

int VersionProblem::GetPackageVersion(int packageId) 
{
  IntVar & var = GetPackageVersionVar(packageId);
  if (1 == var.size()) return var.val();
  return UNRESOLVED_VARIABLE;
}
bool VersionProblem::GetPackageDisabledState(int packageId) 
{
  return disabled_package_variables[packageId].val() == 1;
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

int VersionProblem::GetDisabledVariableCount()
{
  if (total_disabled.min() == total_disabled.max()) {
    return total_disabled.min();
  } else {
    return UNRESOLVED_VARIABLE;
  }
}
  

// Utility
void VersionProblem::Print(std::ostream & out) 
{
  out << "Version problem dump: " << cur_package << "/" << size << " packages used/allocated" << std::endl;
  out << "Total Disabled variables: " << total_disabled.min() << " - " << total_disabled.max() << std::endl;
  out << "preferred_at_latest: " << preferred_at_latest << std::endl;
  out << "total_preferred_at_latest: " << total_preferred_at_latest << std::endl;
  
  for (int i = 0; i < cur_package; i++) {
    out << "\t";
    PrintPackageVar(out, i);
    out << std::endl;
  }
  out.flush();
}

// TODO: Validate package ids !

void VersionProblem::PrintPackageVar(std::ostream & out, int packageId) 
{
  // Hack Alert: we could have the package variable in one of two places, but we don't clearly distinguish where.
  IntVar & var = GetPackageVersionVar(packageId);
  out << "PackageId: " << packageId <<  " Sltn: " << var.min() << " - " << var.max() << " afc: " << var.afc();
  
  out << " disabled: ";
  if (disabled_package_variables[packageId].min() == disabled_package_variables[packageId].max()) {
    out << disabled_package_variables[packageId].min();
  } else {
    out << disabled_package_variables[packageId].min() << " - " << disabled_package_variables[packageId].max();
  }
}

bool VersionProblem::CheckPackageId(int id) 
{
  return (id < size);
}

VersionProblem * VersionProblem::Solve(VersionProblem * problem) 
{
  problem->Finalize();
  problem->status();
#ifdef DEBUG
  std::cout << "Before solve" << std::endl;
  problem->Print(std::cout);
#endif //DEBUG

  Restart<VersionProblem> solver(problem);

  VersionProblem *best_solution = NULL;
  while (VersionProblem *solution = solver.next())
    {
      if (best_solution != NULL) 
	{
	  delete best_solution;
	}
      best_solution = solution;
#ifdef DEBUG
      const Search::Statistics & stats = solver.statistics();
      std::cout << "Solver stats: Prop:" << stats.propagate << " Fail:" << stats.fail << " Node:" << stats.node;
      std::cout << " Depth:" << stats.depth << " memory:" << stats.memory << std::endl;
      //      std::cout << stats << std::endl;
      std::cout << "Solution:" << std::endl;
      solution->Print(std::cout);
#endif //DEBUG
    }
  return best_solution;
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
