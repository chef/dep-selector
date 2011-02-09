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

VersionProblem::VersionProblem() 
  : packages()
{


}


// Clone constructor; check gecode rules for this...
VersionProblem::VersionProblem(bool share, VersionProblem & s) 
  : Script(share, s),
    packages() // TODO Check if this should be copy constructor???
{
  // TODO: Update variables???
  
}

VersionProblem::~VersionProblem() {
  std::vector<Package *>::iterator it;
  for (it = packages.begin(); it < packages.end(); it++) {
    delete *it;
  }  
}


Package * 
VersionProblem::AddPackage(int minVersion, int maxVersion, int currentVersion) 
{
  Package * package = new Package(*this, minVersion,maxVersion,currentVersion);
  int index = packages.size();
  packages.push_back(package);
  package->index = index;
}

bool 
VersionProblem::AddVersionConstraint(Package* pkg, int version, 
				     Package* dependentPackage, int minDependentVersion, int maxDependentVersion) 

{

}

bool VersionProblem::Solve() 
{

}

int VersionProblem::GetPackageVersion(Package* pkg) 
{

}
  
// Support for gecode
Space* VersionProblem::copy(bool share) 
{
  return new VersionProblem(share,*this);
}

// Utility
void VersionProblem::Print(std::ostream & out) 
{
  out << "Version problem dump: " << packages.size() << " elements" << std::endl;
  std::vector<Package *>::iterator it;
  for (it = packages.begin(); it < packages.end(); it++) {
    out << "\t" << **it << std::endl;
  }
}
