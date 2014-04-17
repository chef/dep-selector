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

require 'dep_selector/version_constraint'

module DepSelector
  class Dependency
    attr_reader :package, :constraint

    def initialize(package, constraint=nil)
      @package = package
      @constraint = constraint || VersionConstraint.new
    end

    def to_s(incl_densely_packed_versions = false)
      range = package.densely_packed_versions[constraint]
      "(#{package.name} #{constraint.to_s}#{incl_densely_packed_versions ? " (#{range})" : ''})"
    end

    def ==(o)
      o.respond_to?(:package) && package == o.package &&
        o.respond_to?(:constraint) && constraint == o.constraint
    end

    def eql?(o)
      self.class == o.class && self == o
    end

    def hash
      @hashcode ||= to_s.hash
    end

  end
end
