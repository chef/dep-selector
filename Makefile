t:
	bundle install
	USE_SYSTEM_GECODE=1 gem build dep_selector.gemspec
	USE_SYSTEM_GECODE=1 gem install dep_selector-1.0.3.gem
