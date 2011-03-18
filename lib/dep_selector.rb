#
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Mark Anderson (<mark@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'dep_selector/dep_selector_version'

require 'dep_selector/selector'
require 'dep_selector/dependency_graph'
require 'dep_selector/package'
require 'dep_selector/package_version'
require 'dep_selector/dependency'
require 'dep_selector/solution_constraint'
require 'dep_selector/version'
require 'dep_selector/version_constraint'
require 'dep_selector/exceptions'

# error reporting
require 'dep_selector/error_reporter'
require 'dep_selector/error_reporter/simple_tree_traverser'
