/* -*- mode: C++; c-basic-offset: 2; indent-tabs-mode: nil -*- */

#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

using namespace Gecode;

//
// g++ -g simple_dependency.cpp -lgecodesupport -lgecodekernel -lgecodeint -lgecodesearch -lgecodedriver -lpthread -ldl   -lstdc++ -o simple_dependency
//


class SimpleDependency : public Script {
protected:
  static const int PKG_COUNT = 11;
  
  IntVarArray package_versions;
  IntArgs disabled_package_weights; 
  BoolVarArray disabled_package_variables;
  IntVar total_disabled;
public:
  /// Actual model
  SimpleDependency(const Options& opt) : 
    package_versions(*this, PKG_COUNT, -1, 10), 
    disabled_package_variables(*this, PKG_COUNT, 0, 1),
    total_disabled(*this, 0, 10*PKG_COUNT)  
  {
    Problem2();

    branch(*this, disabled_package_variables, INT_VAR_SIZE_MIN, INT_VAL_MIN);
    branch(*this, package_versions, INT_VAR_SIZE_MIN, INT_VAL_MAX);
    branch(*this, total_disabled, INT_VAL_MIN);
  }

  void SetupDomain1() {
    dom(*this, package_versions[0], -1, 0);
    dom(*this, package_versions[1], -1, 1);
    dom(*this, package_versions[2], -1, 0);
    dom(*this, package_versions[3], -1, 1);
    dom(*this, package_versions[4], -1, 0);
    dom(*this, package_versions[5], -1, 0);
    dom(*this, package_versions[6], -1, 2);
    dom(*this, package_versions[7], -1, 0);
    dom(*this, package_versions[8], -1, 0);
    dom(*this, package_versions[9], -1, -1);
    dom(*this, package_versions[10], 0, 0);
  }

  void SetupDependencies1() {
    AddVersionConstraint(0, 0, 1, 0, 1);
    AddVersionConstraint(2, 0, 1, 0, 0);
    AddVersionConstraint(1, 0, 3, 0, 1);
    AddVersionConstraint(1, 0, 4, 0, 0);
    AddVersionConstraint(1, 1, 3, 1, 1);
    AddVersionConstraint(1, 1, 5, 0, 0);
    AddVersionConstraint(7, 0, 3, -2, -2);
    AddVersionConstraint(8, 0, 9, -2, -2);
    AddVersionConstraint(10, 0, 7, 0, 0);
  }


  void Problem1() {
    std::cout << "Setting up " << __FUNCTION__ << std::endl;
    SetupDomain1();
    SetupDependencies1();
 
    IntArgs package_weights(PKG_COUNT, 10, 10, 10, 10, 10,  10, 10, 10, 10, 10, 10);
    linear(*this, package_weights, disabled_package_variables, IRT_EQ, total_disabled);

    std::cout << "Package versions:           " << package_versions << std::endl;
    std::cout << "Disabled package variables: " << disabled_package_variables << std::endl;
    std::cout << "Package weights             " << package_weights << std::endl;
    std::cout << "Total disabled:             " << total_disabled << std::endl;
  }


  void Problem2() {
    std::cout << "Setting up " << __FUNCTION__ << std::endl;
    SetupDomain1();
    SetupDependencies1();
 
    //    IntArgs package_weights(PKG_COUNT, 10, 10, 10, 10, 10,  10, 10, 5, 10, 10 );
    //                                  0   1   2   3   4    5   6   7   8   9  10
    IntArgs package_weights(PKG_COUNT, 10, 10, 10, 01, 10,  10, 10, 10, 10, 01, 10 );
    linear(*this, package_weights, disabled_package_variables, IRT_EQ, total_disabled);

    std::cout << "Package versions:           " << package_versions << std::endl;
    std::cout << "Disabled package variables: " << disabled_package_variables << std::endl;
    std::cout << "Package weights             " << package_weights << std::endl;
    std::cout << "Total disabled:             " << total_disabled << std::endl;
  }


  bool AddVersionConstraint(int packageId, int version, 
			    int dependentPackageId, int minDependentVersion, int maxDependentVersion) 
  {
    BoolVar version_match(*this, 0, 1);
    BoolVar depend_match(*this, 0, 1);
    BoolVar predicated_depend_match(*this, 0, 1);
    
    std::cout << "Add VC for " << packageId << " @ " << version << " depPkg " << dependentPackageId;
    std::cout << " [ " << minDependentVersion << ", " << maxDependentVersion << " ]" << std::endl;
    std::cout.flush();

    //version_flags << version_match;
    // Constrain pred to reify package @ version
    rel(*this, package_versions[packageId], IRT_EQ, version, version_match);
    // Add the predicated version constraints imposed on dependent package
    dom(*this, package_versions[dependentPackageId], minDependentVersion, maxDependentVersion, depend_match);
    // disabled_package_variables[dependentPackageId] OR depend_match <=> version_match
    
    rel(*this, disabled_package_variables[dependentPackageId], BOT_OR, depend_match, predicated_depend_match);
    rel(*this, version_match, BOT_IMP, predicated_depend_match, 1);  
  }
  
  
  /// Print solution
  virtual void
  print(std::ostream& os) const {
    os << "\t" << package_versions << std::endl;
    os << "\t" << disabled_package_variables << std::endl;
    os << "\t" << total_disabled << std::endl;
  }

  virtual void constrain(const Space & _b) 
  {
    const SimpleDependency& b = static_cast<const SimpleDependency &>(_b);
    int total_disabled_value = b.total_disabled.val();
    rel(*this, total_disabled, IRT_LE, total_disabled_value);
  }

  /// Constructor for cloning \a s
  SimpleDependency(bool share, SimpleDependency& s) : 
    Script(share,s),
    package_versions(s.package_versions), 
    disabled_package_variables(s.disabled_package_variables),
    total_disabled(s.total_disabled)  
  {
    package_versions.update(*this, share, s.package_versions);
    disabled_package_variables.update(*this, share, s.disabled_package_variables);
    total_disabled.update(*this, share, s.total_disabled);
  }
  /// Copy during cloning
  virtual Space*
  copy(bool share) {
    return new SimpleDependency(share,*this);
  }
};

/** \brief Main-function
 *  \relates Money
 */
int
main(int argc, char* argv[]) {
  Options opt("Solve dependency");
  opt.solutions(0);
  opt.iterations(20000);
  opt.parse(argc,argv);
  for (int i = 0; i < 1; i++) 
    //    Script::run<SimpleDependency,Restart,Options>(opt);
    Script::run<SimpleDependency,BAB,Options>(opt);
  return 0;
}

// STATISTICS: example-any

