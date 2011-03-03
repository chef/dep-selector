/* -*- mode: C++; c-basic-offset: 2; indent-tabs-mode: nil -*- */

#include <gecode/driver.hh>
#include <gecode/int.hh>
#include <gecode/minimodel.hh>

using namespace Gecode;

class ChangeMaker : public MaximizeScript {
protected:
  // Denomination of coins
  //  static const int denominations []  = { 1, 5, 10, 20, 50, 100, 200 };
  static const int denomination_count = 7;
  // Change to make
  static const int total_def = 99;
  IntVarArray coins;
  IntVar total_coins;
public:
  /// Actual model
  ChangeMaker(const Options& opt) : coins(*this, denomination_count, 0, total_def), total_coins(*this, 0, total_def)  {
   
    IntArgs denomination_arg(denomination_count, 1, 5, 10, 25, 50, 100, 200);
    for (int i = 0; i < denomination_count; i++) {
      int range = total_def / denomination_arg[i];
      dom(*this, coins[i], 0, range);
    }

    std::cout << "Coin denominations: " << denomination_arg << std::endl;
    std::cout << "Coins: " << coins << std::endl;
    linear(*this, denomination_arg, coins, IRT_EQ, total_def);
    linear(*this, coins, IRT_EQ, total_coins);
    //rel(*this, total, IRT_EQ, total_def);
    branch(*this, coins, INT_VAR_SIZE_MIN, INT_VAL_MAX);
    //branch(*this, total, INT_VAL_MIN);
  }
  /// Print solution
  virtual void
  print(std::ostream& os) const {
    os << "\t" << coins << std::endl;
  }
  virtual IntVar cost() const {
    return total_coins;
  }

  /// Constructor for cloning \a s
  ChangeMaker(bool share, ChangeMaker& s) : MaximizeScript(share,s), coins(s.coins), total_coins(s.total_coins) {
    coins.update(*this, share, s.coins);
    total_coins.update(*this, share, s.total_coins);
  }
  /// Copy during cloning
  virtual Space*
  copy(bool share) {
    return new ChangeMaker(share,*this);
  }
};

/** \brief Main-function
 *  \relates Money
 */
int
main(int argc, char* argv[]) {
  Options opt("Make change");
  opt.solutions(0);
  opt.iterations(20000);
  opt.parse(argc,argv);
  MaximizeScript::run<ChangeMaker,Restart,Options>(opt);
  return 0;
}

// STATISTICS: example-any

