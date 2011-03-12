# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dep_selector}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christopher Walters", "Mark Anderson"]
  s.autorequire = %q{dep_selector}
  s.date = %q{2011-03-11}
  s.description = %q{Given packages, versions, and a dependency graph, find a valid assignment of package versions}
  s.email = ["cw@opscode.com", "mark@opscode.com"]
  s.extensions = ["ext/dep_gecode/extconf.rb"]
  s.files = ["lib/dep_gecode.bundle", "lib/dep_selector/densely_packed_set.rb", "lib/dep_selector/dependency.rb", "lib/dep_selector/dependency_graph.rb", "lib/dep_selector/error_reporter/simple_tree_traverser.rb", "lib/dep_selector/error_reporter.rb", "lib/dep_selector/exceptions.rb", "lib/dep_selector/gecode_wrapper.rb", "lib/dep_selector/package.rb", "lib/dep_selector/package_version.rb", "lib/dep_selector/selector.rb", "lib/dep_selector/solution_constraint.rb", "lib/dep_selector/version.rb", "lib/dep_selector/version_constraint.rb", "lib/dep_selector.rb", "lib/gecode.bundle", "ext/dep_gecode/dep_selector_swig.i", "ext/dep_gecode/dep_selector_swig_wrap.cxx", "ext/dep_gecode/dep_selector_to_gecode.h", "ext/dep_gecode/dep_selector_to_gecode_interface.h", "ext/dep_gecode/save/dep_selector_to_gecode.h", "ext/dep_gecode/save/version_problem_overconstrained.h", "ext/dep_gecode/dep_selector_to_gecode.cpp", "ext/dep_gecode/dep_selector_to_gecode_interface.cpp", "ext/dep_gecode/save/dep_selector_to_gecode.cpp", "ext/dep_gecode/save/version_problem_overconstrained.cpp", "ext/dep_gecode/extconf.rb", "ext/dep_gecode/lib/dep_selector_to_gecode.rb"]
  s.has_rdoc = false
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Given packages, versions, and a dependency graph, find a valid assignment of package versions}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
